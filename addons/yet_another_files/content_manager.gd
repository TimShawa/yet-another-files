@tool
extends PanelContainer
class_name ContentManager

#region Properties

@onready var path_interactive: HBoxContainer = $Container/Header/HBoxContainer/Path/ScrollContainer/PathInteractive
const CONTENT_ITEM: Array[PackedScene] = [
	null,
	null,
	preload('res://addons/yet_another_files/components/file_icons/file_icon_medium.scn'),
	preload('res://addons/yet_another_files/components/file_icons/file_icon_big.scn'),
	preload('res://addons/yet_another_files/components/file_icons/file_icon_large.scn')
]
const PATH_ENTRY: PackedScene = preload('res://addons/yet_another_files/components/path_list_entry.scn')
var filesystem: EditorFileSystem
var plugin: EditorPlugin
var files_to_import: PackedStringArray = []
var current_dir: DirAccess = DirAccess.open('res://')
var selection: Array[String] = []
var active_elem: int = -1
var filter_search: String = ''
var create_new: Callable = func(): pass
var show_hidden := false
var full_inspectable_paths: PackedStringArray = [ 'res://addons/', 'res://' ]
var hide_import_alias := true
var hide_handheld_controls := false
var old_fs_path := 'res://'

enum ESettingsPopupOption {
	SHOW_HIDDEN,
	HIDE_IMPORT_ALIAS,
	HIDE_HANDHELD_CONTROLS
}

enum EIconSize { TINY, SMALL, MEDIUM, BIG, LARGE }

#endregion


func _process(delta: float) -> void:
	if selecting_box and !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		stop_box_selection()
	if EditorInterface.get_selected_paths().size():
		if EditorInterface.get_selected_paths()[0] != old_fs_path:
			file_navigate(EditorInterface.get_selected_paths()[0], true)
			old_fs_path = EditorInterface.get_selected_paths()[0]


func _ready() -> void:
	await get_tree().process_frame
	if filesystem:
		filesystem.connect('filesystem_changed', update_content)
	change_dir(EditorInterface.get_current_path())
	upd_path_label()


#region Import

func _on_file_dialog_files_selected(paths: PackedStringArray) -> void:
	files_to_import = paths


func _on_file_dialog_canceled() -> void:
	files_to_import = []


func _on_file_dialog_confirmed() -> void: pass
	#var copied: PackedStringArray = []
	#var canceled: bool = false
	#for i in range(len(files_to_import)):
		#if !current_dir.file_exists(files_to_import[i].get_file()):
			#file_copy(files_to_import[i])
			#copied.append(files_to_import[i])
		#else:
			#$FileExist.popup_centered($FileExist.size)
			#await $FileExist.changed
			#print($FileExist.state)
			#match $FileExist.state:
				#'canceled':
					#canceled = true
				#'ignored':
					#pass
				#'overwritten':
					#file_copy(files_to_import[i])
					#copied.append(files_to_import[i])
			#$FileExist.reset()
	#print(current_dir.get_files())
	#if canceled:
		#for file in copied:
			#remove_file(file.get_file())
			#if current_dir.file_exists(file + '.import'):
				#remove_file(file + '.import')
	#files_to_import = []
	#filesystem.scan()

#endregion


func upd_path_label() -> void:
	await get_tree().process_frame
	for node in path_interactive.get_children():
		node.queue_free()
	
	var path_list := current_dir.get_current_dir().split('/', 0)
	#path_list.remove_at(0)
	path_list[0] = 'res://'
	
	for i in path_list.size():
		var path: String = '/'.join(path_list.slice(0,i+1))
		var entry: PathListEntry = PATH_ENTRY.instantiate()
		entry.path = path
		path_interactive.add_child(entry)
		entry.show()
		entry.connect_drawer(self)


func get_parent_dir(path: String = current_dir.get_current_dir()):
	var dir := EditorInterface.get_resource_filesystem().get_filesystem_path(path)
	if dir.get_path() != 'res://':
		return dir.get_parent().get_path()
	else:
		return 'res://'


func change_dir(new_dir: String, fs_safe := true) -> Error:
	var err := current_dir.change_dir(new_dir)
	if err == OK:
		if !fs_safe:
			var files = DirAccess.get_files_at(current_dir.get_current_dir())
			if files.size():
				EditorInterface.get_file_system_dock().navigate_to_path(current_dir.get_current_dir().path_join(files[0]))
		selection.clear()
		upd_path_label()
		update_content()
	return err


func _resized() -> void:
	if %ContentField.get_child_count():
		%ContentField.columns = maxi(1, floori(%ContentField.size.x /\
			(%ContentField.get_child(0).size.x + %ContentField.get_theme_constant('h_separation'))))
	else:
		%ContentField.columns = 1


func update_content() -> void:
	current_dir.include_hidden = show_hidden
	var dirs := current_dir.get_directories()
	var files := current_dir.get_files()
	for node in %ContentField.get_children():
		(%ContentField as GridContainer).remove_child(node)
	for dir in dirs:
		if !match_filters(dir):
			continue
		add_content_item(dir, true)
	for file in files:
		if !match_filters(file):
			continue
		var full_inspect := false
		for path in full_inspectable_paths:
			if current_dir.get_current_dir().begins_with(path):
				full_inspect = true
				break
		if full_inspect or filesystem.get_file_type(current_dir.get_current_dir().path_join(file)):
			if hide_import_alias:
				if !file.match('*.import'):
					add_content_item(file)
			else:
				add_content_item(file)
	
	%ContentField.get_node(^'../../EmptyFolder').visible = !%ContentField.get_child_count()
	
	%ContentField.propagate_call('invalidate')
	emit_signal('resized')


func add_content_item(name: String, directory: bool = false) -> DirContentItem:
	var item := CONTENT_ITEM[icon_size].instantiate() as DirContentItem
	%ContentField.add_child(item)
	item.connect('selected', file_select)
	item.connect('opened', func(path,drawer=self): drawer.file_option(0, path))
	item.connect('rmb_selected', file_context)
	item.path = current_dir.get_current_dir().path_join(name) + ('/' if directory else '')
	return item

#region Buttons

func _on_btn_add_pressed() -> void:
	var popup: PopupMenu = $CreateNew as PopupMenu
	if popup.item_count != 5:
		var icon := func(name): return EditorInterface.get_editor_theme().get_icon(name, 'EditorIcons')
		popup.add_icon_item(icon.call('Folder'), 'New Folder...', FileContext.FileMenu.FILE_NEW_FOLDER)
		popup.add_icon_item(icon.call('PackedScene'), 'New Scene...', FileContext.FileMenu.FILE_NEW_SCENE)
		popup.add_icon_item(icon.call('Script'), 'New Script...', FileContext.FileMenu.FILE_NEW_SCRIPT)
		popup.add_icon_item(icon.call('Object'), 'New Resource...', FileContext.FileMenu.FILE_NEW_RESOURCE)
		popup.add_icon_item(icon.call('TextFile'), 'New TextFile...', FileContext.FileMenu.FILE_NEW_TEXTFILE)
	if !popup.is_connected('id_pressed', file_option):
		popup.connect('id_pressed', file_option)
	popup.position = %BtnAdd.global_position + Vector2(0,50)
	popup.show()


func _on_btn_import_pressed() -> void:
	var file_dial := $ImportFiles as FileDialog
	file_dial.current_path = current_dir.get_current_dir()
	file_dial.show()


func _on_btn_save_all_pressed() -> void:
	EditorInterface.save_all_scenes()


func _on_btn_parent_pressed() -> void:
	if current_dir.get_current_dir() != 'res://':
		change_dir('..')

#endregion

#region File Options


func file_select(path: String, mode: StringName = 'exclude') -> void:
	match mode:
		'exclude':
			if selection == [path]:
				selection.clear()
			else:
				selection = [path]
				active_elem = 0
		'toggle':
			if selection.has(path):
				if active_elem != -1 and selection.find(path) == active_elem:
					active_elem = -1
				selection.erase(path)
			else:
				selection.push_front(path)
				active_elem = 0
		'range':
			var start := -1
			var end := -1
			for i: DirContentItem in %ContentField.get_children():
				if i.path == selection[-1]:
					start = i.get_index()
				if i.path == path:
					end = i.get_index()
			if end == start or -1 in [ start, end ]:
				return
			for i in range(min(start, end), max(start, end) + 1):
				if %ContentField.get_child(i).path not in selection:
					selection.push_front(%ContentField.get_child(i).path)
			active_elem = selection.find(path)
	if selection.size():
		EditorInterface.get_file_system_dock().navigate_to_path(current_dir.get_current_dir())
	else:
		active_elem = -1
	%ContentField.propagate_call('update_selection',[selection])


func file_navigate(path: String, fs_safe := false) -> void:
	change_dir(path.get_base_dir(), fs_safe)
	selection = [path]
	#%ContentField.propagate_call('update_selection', [selection])


func file_context(path) -> void:
	if selection.size() < 2 and path not in selection:
		file_select(path)
	var popup := $FileContext as FileContext
	popup.clear()
	popup.context_fill( selection if path != 'void' else [], true )
	popup.show()
	var editor := EditorInterface.get_base_control()
	var pos: Vector2i = editor.get_local_mouse_position()
	pos = (pos + popup.size).clamp(editor.get_begin(), editor.size) - popup.size
	popup.position = pos
	popup.reset_size()


func file_option(op: FileContext.FileMenu, path: String = current_dir.get_current_dir()) -> void:
	if selection.size(): path = selection[0]
	var option := FileContext.FileMenu
	match op:
		
		option.FILE_OPEN:
			if path.ends_with('/'):
				change_dir(path)
			else:
				var file_type = filesystem.get_file_type(path)
				if file_type == &'GDScript':
					EditorInterface.edit_script(load(path))
				elif file_type == &'PackedScene':
					if path not in EditorInterface.get_open_scenes():
						EditorInterface.open_scene_from_path(path)
					var root := get_tree().edited_scene_root
					EditorInterface.edit_node(root)
				elif file_type == &'Resource' or ClassDB.is_parent_class(file_type, &'Resource'):
					EditorInterface.edit_resource(load(path))
				else:
					push_warning('Ignored: File "', path.get_file(), '" cannot be modified within Godot.')
		
		option.FILE_INHERIT:
			EditorInterface.get_file_system_dock().emit_signal('inherit', path)
		
		option.FILE_MAIN_SCENE:
			ProjectSettings.set_setting('application/run/main_scene', path)
			ProjectSettings.save()
			filesystem.scan()
		
		option.FILE_INSTANTIATE:
			EditorInterface.get_file_system_dock().emit_signal('instantiate', [path])
			filesystem.scan()
		
		option.FILE_ADD_FAVORITE:
			var favs = EditorInterface.get_editor_settings().get_favorites()
			favs.append(path)
			EditorInterface.get_editor_settings().set_favorites(favs)
			filesystem.scan()

		option.FILE_REMOVE_FAVORITE:
			var favs = EditorInterface.get_editor_settings().get_favorites()
			if favs.find(path) != -1:
				favs.remove_at(favs.find(path))
			EditorInterface.get_editor_settings().set_favorites(favs)
			filesystem.scan()

		option.FILE_DEPENDENCIES: pass

		option.FILE_OWNERS: pass

		option.FILE_MOVE: pass

		option.FILE_RENAME: pass

		option.FILE_REMOVE:
			# оказалось, дело вовсе не в этом куске кода. на самом деле проблема в выделении файлов
			var popup = AcceptDialog.new()
			popup.dialog_text = 'Dependency fix wasn\'t implemented in this plugin, so deleting files within it may cause hart to your project. Are you sure?'
			popup.ok_button_text = 'Noticed'
			popup.title = 'Warning! Please .'
			add_child(popup)
			popup.popup_centered()
			await popup.confirmed
			popup.queue_free()
			DirAccess.remove_absolute(path)
			%ContentField.propagate_call('invalidate')

		option.FILE_DUPLICATE:
			var dialog := $DuplicateDialog as Window
			var answer: String = await dialog.request_duplicate(path)
			if answer:
				var copy_path: String
				print(path)
				if path.ends_with('/'):
					copy_path = path.get_base_dir().get_base_dir() + answer + '/'
				else:
					copy_path = path.get_base_dir().path_join(answer)
				DirAccess.copy_absolute(path, copy_path)
				filesystem.scan()

		option.FILE_INFO:
			var item: DirContentItem
			for i in %ContentField.get_children():
				if i.path == path:
					item = i
					break
			if item:
				print('---------------- ', item.path, ' ----------------')
				prints( ('Folder:' if item.is_directory else 'File:').rpad(10), item.path.trim_suffix('/').split('/')[-1] + ('/' if item.is_directory else '') )
				prints( 'Location:'.rpad(10), item.path.trim_suffix('/').get_base_dir() + '/' )
				if item.file_type not in [ &'File', &'Folder' ]:
					prints( 'Resource:'.rpad(10), item.file_type )
				elif item.file_type == &'Folder':
					prints( 'Folders:'.rpad(10), DirAccess.get_directories_at(item.path).size() )
					prints( 'Files:'.rpad(10), DirAccess.get_files_at(item.path).size() )
				print()

		option.FILE_REIMPORT:
			filesystem.update_file(path)

		option.FILE_NEW_FOLDER:
			EditorInterface.select_file(current_dir.get_current_dir())
			plugin.create_new(plugin.EDockID.NEW_FOLDER)

		option.FILE_NEW_SCENE:
			EditorInterface.select_file(current_dir.get_current_dir())
			plugin.create_new(plugin.EDockID.NEW_SCENE)

		option.FILE_NEW_SCRIPT:
			var dialog = ScriptCreateDialog.new()
			add_child(dialog)
			dialog.config('Node', current_dir.get_current_dir().path_join('new_script.gd'))
			dialog.popup_centered()
			await dialog.script_created or dialog.canceled
			dialog.queue_free()
			#var answer = await $CreateScript.request_create(path)
			#if answer.size():
				#var access := FileAccess.open(answer[0], FileAccess.WRITE)
				#access.store_pascal_string(answer[1])

		option.FILE_COPY_PATH:
			DisplayServer.clipboard_set(path)

		option.FILE_COPY_UID:
			DisplayServer.clipboard_set(String.num_int64(ResourceLoader.get_resource_uid(path)))

		option.FILE_NEW_RESOURCE:
			plugin.create_new(plugin.EDockID.NEW_RESOURCE)

		option.FILE_NEW_TEXTFILE:
			var dialog := FileDialog.new()
			dialog.root_subfolder = 'res://'
			dialog.current_dir = current_dir.get_current_dir()
			for ext: String in ResourceLoader.get_recognized_extensions_for_type('TextFile'):
				dialog.add_filter('*.' + ext, ext.to_upper())
			var wait := func(confirmed): return confirmed
			dialog.connect('canceled', func(cal = wait): call.call(false))
			dialog.connect('confirmed', func(call = wait): call.call(true))
			await wait
			dialog.queue_free()

#endregion


func _on_content_field_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and !event.is_echo():
			if event.get_keycode_with_modifiers() == KEY_A:
				if selection.size() != %ContentField.get_child_count():
					selection.clear()
					for i in %ContentField.get_children():
						selection.append(i.path)
				else:
					selection.clear()
				%ContentField.propagate_call('update_selection', [selection])
	if event is InputEventMouseButton:
		if event.is_released() and !event.is_echo():
			if event.button_index == MOUSE_BUTTON_LEFT:
				if !selecting_box:
					selection.clear()
					%ContentField.propagate_call('update_selection', [selection])
					%ContentField.grab_focus()
			if event.button_index == MOUSE_BUTTON_RIGHT:
				file_context('void')
	
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if selecting_box:
				var a: Vector2i = box_selection_origin
				var b: Vector2i = Vector2i(get_global_mouse_position())
				$SelectionBox.global_position = Vector2( min(a.x, b.x), min(a.y, b.y) )
				$SelectionBox.size = (b-a).abs()
				box_select(selecting_box)
			else:
				if OS.get_name() in [ &'Android', &'iOS' ]:
					if event.button_mask == MOUSE_BUTTON_MASK_LEFT | KEY_MASK_CMD_OR_CTRL:
						start_box_selection(&'set')
					elif event.button_mask == MOUSE_BUTTON_MASK_LEFT | KEY_MASK_SHIFT:
						start_box_selection(&'add')
				else:
					if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
						start_box_selection(&'set')
					elif event.button_mask == MOUSE_BUTTON_MASK_LEFT | KEY_MASK_SHIFT:
						start_box_selection(&'add')


func _on_but_settings_ready() -> void:
	await get_tree().create_timer(0.1)
	var popup = %ButSettings.get_popup() as PopupMenu
	popup.connect('id_pressed', set_setting)
	popup.hide_on_checkable_item_selection = false
	popup.hide_on_item_selection = false
	popup.clear()
	
	popup.add_separator()
	popup.add_check_item('Show hidden', ESettingsPopupOption.SHOW_HIDDEN)
	popup.add_check_item('Hide *.import files', ESettingsPopupOption.HIDE_IMPORT_ALIAS)
	popup.add_check_item('Hide handheld controls', ESettingsPopupOption.HIDE_HANDHELD_CONTROLS)
	
	var icon_size_popup := PopupMenu.new()
	popup.hide_on_checkable_item_selection = false
	popup.hide_on_item_selection = false
	for i in EIconSize.size():
		icon_size_popup.add_check_item(EIconSize.keys()[i], i)
		icon_size_popup.set_item_disabled(i, i < EIconSize.MEDIUM)
	icon_size_popup.connect('id_pressed', change_icon_size)
	icon_size_popup.name = 'IconSizePopup'
	popup.add_child(icon_size_popup)
	
	popup.add_submenu_item('Icon size', 'IconSizePopup')
	popup.add_separator()
	
	popup.set_item_checked(popup.get_item_index(ESettingsPopupOption.SHOW_HIDDEN), show_hidden)
	popup.set_item_checked(popup.get_item_index(ESettingsPopupOption.HIDE_IMPORT_ALIAS), hide_import_alias)
	popup.set_item_checked(popup.get_item_index(ESettingsPopupOption.HIDE_HANDHELD_CONTROLS), hide_handheld_controls)
	change_icon_size(EIconSize.BIG)


func set_setting(id) -> void:
	var popup = %ButSettings.get_popup() as PopupMenu
	match id:
		ESettingsPopupOption.SHOW_HIDDEN:
			show_hidden = !show_hidden
			popup.set_item_checked(popup.get_item_index(id), show_hidden)
			update_content()
		ESettingsPopupOption.HIDE_IMPORT_ALIAS:
			hide_import_alias = !hide_import_alias
			popup.set_item_checked(popup.get_item_index(id), hide_import_alias)
			update_content()
		ESettingsPopupOption.HIDE_HANDHELD_CONTROLS:
			hide_handheld_controls = !hide_handheld_controls
			popup.set_item_checked(popup.get_item_index(id), hide_handheld_controls)
			%ContentField.propagate_call('update_display')


#region Box Selection

var selecting_box := &''
var box_selection_origin := Vector2.ZERO

func box_select(mode: StringName) -> void:
	if mode == &'set':
		selection.clear()
	for i: DirContentItem in %ContentField.get_children():
		if i._under_box_selection($SelectionBox.get_global_rect()):
			if i.path in selection:
				selection.erase(i.path)
			selection.push_back(i.path)
	%ContentField.propagate_call('update_selection', [selection])


func start_box_selection(mode: StringName) -> void:
	selecting_box = mode
	var box := $SelectionBox as Panel
	box_selection_origin = get_global_mouse_position()
	box.global_position = box_selection_origin
	box.size = Vector2.ZERO
	box.visible = true


func stop_box_selection() -> void:
	selecting_box = &''
	var box := $SelectionBox as Panel
	box.visible = false
	box_selection_origin = Vector2.ZERO
	box.position = box_selection_origin
	box.size = Vector2.ZERO

#endregion


func _on_content_field_focus_exited() -> void:
	%ContentField.propagate_call(&'switch_focus', [true])


func _on_content_field_focus_entered() -> void:
	%ContentField.propagate_call(&'switch_focus', [false])

var icon_size := EIconSize.BIG
func change_icon_size(new: EIconSize):
	icon_size = new
	var popup := %ButSettings.get_popup().get_node_or_null(^'IconSizePopup') as PopupMenu
	for i in popup.item_count:
		popup.set_item_checked(i, i == icon_size)
	update_content()


func _on_search_line_text_changed(new_text: String) -> void:
	filter_search = new_text
	update_content()


func match_filters(file: String, rule: StringName = &'contains'):
	if filter_search.is_empty():
		return true
	match rule:
		&'begins':
			return file.begins_with(filter_search)
		&'contains':
			return file.contains(filter_search)
		&'mask':
			return file.match(filter_search)
		&'maskn':
			return file.matchn(filter_search)
	return true
