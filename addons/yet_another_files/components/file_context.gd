@tool
extends PopupMenu
class_name FileContext

enum FileMenu {
	FILE_OPEN,
	FILE_INHERIT,
	FILE_MAIN_SCENE,
	FILE_INSTANTIATE,
	FILE_ADD_FAVORITE,
	FILE_REMOVE_FAVORITE,
	FILE_DEPENDENCIES,
	FILE_OWNERS,
	FILE_MOVE,
	FILE_RENAME,
	FILE_REMOVE,
	FILE_DUPLICATE,
	FILE_REIMPORT = 12,
	FILE_INFO,
	FILE_NEW,
	FILE_SHOW_IN_EXPLORER,
	FILE_OPEN_EXTERNAL,
	FILE_OPEN_IN_TERMINAL,
	FILE_NONE, # for idx offset
	FILE_COPY_PATH = 17, # was 16
	FILE_COPY_UID,
	FOLDER_EXPAND_ALL,
	FOLDER_COLLAPSE_ALL,
	FILE_NEW_RESOURCE,
	FILE_NEW_TEXTFILE,
	FILE_NEW_FOLDER,
	FILE_NEW_SCRIPT,
	FILE_NEW_SCENE,
}

var action: Callable = func(id): print(id, 'not connected')
var drawer_path: NodePath

# Copied from engine source code
func context_fill(paths: PackedStringArray, display_path_dependent_options: bool, in_tree: bool = false):
	# Add options for files and folders.
	if paths.has('res://'):
		paths.remove_at(paths.find('res://'))
	
	if !paths.size():
		add_icon_item( icon(&'Folder'), tr('New Folder...'), FileMenu.FILE_NEW_FOLDER )
		add_icon_item( icon(&'PackedScene'), tr('New Scene...'), FileMenu.FILE_NEW_SCENE )
		add_icon_item( icon(&'Script'), tr('New Script...'), FileMenu.FILE_NEW_SCRIPT )
		add_icon_item( icon(&'Object'), tr('New Resource...'), FileMenu.FILE_NEW_RESOURCE )
		add_icon_item( icon(&'TextFile'), tr('New TextFile...'), FileMenu.FILE_NEW_TEXTFILE )
		return
	
	var filenames: PackedStringArray
	var foldernames: PackedStringArray
	
	var favorites_list: PackedStringArray = EditorInterface.get_editor_settings().get_favorites()
	var all_files := true
	var all_files_scenes := true
	var all_folders := true
	var all_favorites := true
	var all_not_favorites := true
	
	for path in paths:
		if path.ends_with('/'):
			foldernames.append(path)
			all_files = false
		else:
			filenames.append(path)
			all_folders = false
			all_files_scenes = all_files_scenes and EditorInterface.get_resource_filesystem().get_file_type(path) == 'PackedScene'
		var found := false
		
		# Check for favorites.
		for fav in favorites_list:
			if fav == path:
				found = true
				break
		if found:
			all_not_favorites = false
		else:
			all_favorites = false
	
	#printt(all_favorites, all_files, all_files_scenes, all_folders, all_not_favorites)
	
	if all_files:
		if all_files_scenes:
			if filenames.size() == 1:
				add_icon_item( icon(&'Load'), tr('Open Scene'), FileMenu.FILE_OPEN )
				add_icon_item( icon(&'CreateNewSceneFrom'), tr('New Inherited Scene'), FileMenu.FILE_INHERIT )
				if ProjectSettings.get_setting('application/run/main_scene') != filenames[0]:
					add_icon_item( icon(&'PlayScene'), tr('Set as Main Scene'), FileMenu.FILE_MAIN_SCENE )
			else:
				add_icon_item( icon(&'Load'), tr('Open Scenes'), FileMenu.FILE_OPEN )
			add_icon_item( icon(&'Instance'), tr('Instantiate'), FileMenu.FILE_INSTANTIATE )
			add_separator()
		elif filenames.size() == 1:
			add_icon_item( icon(&'Load'), tr('Open'), FileMenu.FILE_OPEN )
			add_separator()
		
		if filenames.size() == 1:
			add_item( tr('Edit Dependencies...'), FileMenu.FILE_DEPENDENCIES )
			add_item( tr('View Owners...'), FileMenu.FILE_OWNERS )
			add_separator()
	
	if paths.size() == 1 and display_path_dependent_options:
		var new_menu := PopupMenu.new()
		new_menu.name = 'New'
		new_menu.connect('id_pressed', func(id, f = action): f.call(id))
		
		add_child(new_menu)
		add_submenu_item( tr('Create New'), 'New', FileMenu.FILE_NEW )
		set_item_icon( get_item_index(FileMenu.FILE_NEW), icon(&'Add') )
		
		new_menu.add_icon_item( icon(&'Folder'), tr('Folder...'), FileMenu.FILE_NEW_FOLDER )
		new_menu.add_icon_item( icon(&'PackedScene'), tr('Scene...'), FileMenu.FILE_NEW_SCENE )
		new_menu.add_icon_item( icon(&'Script'), tr('Script...'), FileMenu.FILE_NEW_SCRIPT )
		new_menu.add_icon_item( icon(&'Object'), tr('Resource...'), FileMenu.FILE_NEW_RESOURCE )
		new_menu.add_icon_item( icon(&'TextFile'), tr('TextFile...'), FileMenu.FILE_NEW_TEXTFILE )
		add_separator()
	
	if all_folders and foldernames.size() > 0:
		if in_tree:
			add_icon_item( icon(&'Load'), tr('Expand Folder'), FileMenu.FILE_OPEN )
			
			if foldernames.size() == 1:
				add_icon_item( icon(&'GuiTreeArrowDown'), tr('Expand Hierarchy'), FileMenu.FOLDER_EXPAND_ALL )
				add_icon_item( icon(&'GuiTreeArrowRight'), tr('Collapse Hierarchy'), FileMenu.FOLDER_COLLAPSE_ALL )
			
			add_separator()
		#else:
			#add_icon_item( icon(&'Load'), tr('Open'), FileMenu.FILE_OPEN )
			#add_separator()
		if paths[0] != 'res://':
			var folder_colors_menu := PopupMenu.new()
			folder_colors_menu.name = 'FolderColor'
			
			folder_colors_menu.add_icon_item(icon(&'Load'), tr('Default (Reset)'), 20)
			
			var picker := ColorPicker.new()
			folder_colors_menu.add_child(picker)
			folder_colors_menu.add_submenu_item(tr('Select New...'), 'FolderColor')
			folder_colors_menu.set_item_icon(-1, icon(&'Add'))
			folder_colors_menu.set_item_id(-1, 21)
			
			add_child(folder_colors_menu)
			add_submenu_item(tr('Set Folder Color...'), 'FolderColor')
			add_separator()
	
	if paths.size() == 1: 
		add_icon_item( icon(&'ActionCopy'),  tr('Copy Path'), FileMenu.FILE_COPY_PATH )
		if ResourceLoader.get_resource_uid(paths[0]) != ResourceUID.INVALID_ID:
			add_icon_item( icon(&'Instance'), tr('Copy UID'), FileMenu.FILE_COPY_UID )
		if paths[0] != 'res://':
			add_icon_item( icon(&'Rename'), tr('Rename'), FileMenu.FILE_RENAME )
			add_icon_item( icon(&'Duplicate'), tr('Duplicate'), FileMenu.FILE_DUPLICATE )
	
	if paths.size() > 1 or paths[0] != 'res://':
		add_icon_item( icon(&'MoveUp'), tr('Move/Duplicate To...'), FileMenu.FILE_MOVE )
		add_icon_item( icon(&'Remove'), tr('Remove'), FileMenu.FILE_REMOVE )
	
	add_separator()
	
	if paths.size() >= 1:
		if !all_favorites:
			add_icon_item( icon(&'Favorites'), tr('Add to Favorites'), FileMenu.FILE_ADD_FAVORITE )
		if !all_not_favorites:
			add_icon_item( icon(&'NonFavorite'), tr('Remove from Favorites'), FileMenu.FILE_REMOVE_FAVORITE )
	
	var extension_list := ResourceLoader.get_recognized_extensions_for_type('Resource')
	
	var resource_valid := true
	var main_extension := ''
	
	for i in paths.size():
		var extension := paths[i].get_extension()
		if extension_list.has(extension):
			if !main_extension:
				main_extension = extension
			elif extension != main_extension:
				resource_valid = false
				break
		else:
			resource_valid = false
			break
	
	if resource_valid:
		add_icon_item( icon(&'Load'), tr('Reimport'), FileMenu.FILE_REIMPORT )
	
	if paths.size() == 1:
		var path = paths[0]
		
		if OS.get_name() not in [ 'Android', 'Web' ]:
			add_separator()
			var is_directory = path.ends_with('/')
			
			add_icon_item( icon(&'Filesystem'), tr('Open in File Manager') if is_directory else tr('Show in File Manager'), FileMenu.FILE_SHOW_IN_EXPLORER )
			
			if !is_directory:
				add_icon_item( icon(&'ExternalLink'), tr('Open in External Program'), FileMenu.FILE_OPEN_EXTERNAL )
			
			add_icon_item( icon(&'Terminal'), tr('Open in Terminal') if is_directory else tr('Show in Terminal') )


#func _ready() -> void:
	#connect('id_pressed', func(id, f = action): f.call(id))


func icon(name: StringName) -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(name, 'EditorIcons')


func _id_pressed(id: int):
	var drawer = $'..' as ContentManager
	drawer.file_option(id)
