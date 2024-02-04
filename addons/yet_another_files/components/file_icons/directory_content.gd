@tool
extends Control
class_name DirContentItem


# Connect [handheld.gui_input] and [self._on_focus_entered] manually


signal rmb_selected(pos, button)
signal selected(item, mode)
signal opened(path, is_dir)
signal size_changed(w)

@export_group('References')
@export var file_preview: ThumbnailPanel
@export var handheld_selector: CheckBox
@export var filename_label: Label
@export var THEME: Node
@export_group('')
var path: String = 'res://icon.svg':	set = set_path
var is_directory := false
var folder_color := Color.GRAY
var selection := 0
var file_type := &'File':
	set(value):
		file_type = value
		if 'filetype_label' in self:
			get('filetype_label').set_text(file_type if file_type not in [ &'File', &'Folder' ] else '')
const FOLDER_ICON: Texture2D = preload('res://addons/yet_another_files/assets/icons/icon_folder.png')
@export var icon_size := Vector2(110, 110*1.6):	set = set_icon_size


func set_icon_size(value): # TODO need to reimplement
	var S := EditorInterface.get_editor_scale()
	if icon_size != value:
		emit_signal('size_changed')
	icon_size = value
	custom_minimum_size = icon_size * S
	reset_size()


func update_display() -> void:
	if 'file_panel' in self and 'folder_panel' in self:
		get('file_panel').visible = !is_directory
		get('folder_panel').visible = is_directory


func _enter_tree() -> void:
	icon_size = icon_size
	#connect('focus_entered', _on_focus_entered)


func invalidate() -> void:
	if is_directory:
		if !DirAccess.dir_exists_absolute(path):
			queue_free()
	else:
		if !FileAccess.file_exists(path):
			queue_free()


func set_path(value: String) -> void:
	path = value.replace('///', '//')
	if path.ends_with('/'):
		is_directory = true
		file_type = &'Folder'
		filename_label.text = path.split('/',0)[-1]
		if $'..'.owner.plugin:
			folder_color = $'..'.owner.plugin.config_folder_colors(&'get', path, Color.DARK_GRAY).value
	else:
		is_directory = false
		file_type = get_file_type(path)
		filename_label.text = path.get_file()
	update_selection($'..'.owner.selection)
	update_display()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var scroll := get_node_or_null(^'../..') as ScrollContainer
		if scroll:
			scroll.scroll_vertical -= event.relative.y
	if event is InputEventMouseButton:
		accept_event()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released() and !event.is_echo() and !event.double_click:
				if event.get_modifiers_mask() == KEY_MASK_CTRL:
					emit_signal('selected', path, 'toggle')
				elif event.get_modifiers_mask() == KEY_MASK_SHIFT:
					emit_signal('selected', path, 'range')
				elif !event.get_modifiers_mask():
					emit_signal('selected', path)
			if event.double_click:
				emit_signal('opened', path)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.double_click:
				print('dbck')
			if event.is_released() and !event.is_echo():
				emit_signal('rmb_selected', path)


func update_selection(paths: Array) -> void:
	selection = 0
	if path in $'..'.owner.selection:
		selection = 1
		if $'..'.owner.selection.find(path) == $'..'.owner.active_elem and $'..'.owner.active_elem != -1:
			selection = 2
	handheld_selector.set_deferred('button_pressed', selection)
	update_display()


func _under_box_selection(box_rect: Rect2) -> bool:
	return box_rect.intersects( get_global_rect() )


func _drop_data(at_position: Vector2, data: Variant) -> void:
	pass


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return false


func _get_drag_data(at_position: Vector2) -> Variant:
	if _is_handheld():
		return null
	var selection = $'..'.owner.selection
	var preview := Label.new()
	for file: String in selection:
		preview.text += file.get_file()
	set_drag_preview(preview)
	var data: Dictionary = {
		'type': 'files',
		'files': [path],
		'from': self
	}
	return data


static func get_file_type(path: String) -> StringName:
	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem()
	var file_type: StringName = filesystem.get_file_type(path)
	return file_type if file_type else &'File'


func _is_handheld() -> bool:
	if ($'..'.owner as ContentManager).hide_handheld_controls:
		return false
	return OS.get_name() in [ &'Android', &'iOS' ]


func _on_handheld_selector_gui_input(event: InputEvent = null) -> void:
	if event:
		if event is InputEventMouseButton:
			if event.is_released() and !event.is_echo():
				match event.button_index:
					MOUSE_BUTTON_LEFT:
						emit_signal('selected', path, 'toggle')
					MOUSE_BUTTON_RIGHT:
						emit_signal('selected', path, 'range')
	handheld_selector.button_pressed = selection >= 0


func switch_focus(value):
	if value:
		focus_mode = Control.FOCUS_CLICK
	else:
		focus_mode = Control.FOCUS_NONE
	update_display()


func _on_focus_entered() -> void:
	emit_signal('selected', path)
	var field := $'..'.owner.get_node_or_null(^'%ContentField') as Control
	if field:
		field.grab_focus()
