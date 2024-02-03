@tool
extends EditorPlugin
class_name ContentManagerPlugin

enum EDockID {
	CONTEXT = 2,
	NEW_FOLDER = 11,
	NEW_SCENE = 12,
	NEW_SCRIPT = 13,
	NEW_RESOURCE = 15,
}
@onready var DRAWER: PackedScene = load('res://addons/yet_another_files/content_manager.scn')
var drawer: Control
var filesystem: EditorFileSystem
var hide_native: bool = false
var native_dock: FileSystemDock
var native_dock_layout := EditorPlugin.DOCK_SLOT_LEFT_BR
var dock_children: Array
var bottom = true
const OWN_FAVS := false

func _has_main_screen() -> bool:
	return true
func _get_plugin_name() -> String:
	return 'Content'
func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon('Folder', 'EditorIcons')


func _enter_tree() -> void:
	while !is_instance_valid(filesystem):
		await get_tree().physics_frame
		filesystem = EditorInterface.get_resource_filesystem()
	
	init_configuration()
	drawer = DRAWER.instantiate()
	drawer.filesystem = filesystem
	drawer.plugin = self
	await get_tree().physics_frame
	
	add_control_to_bottom_panel(drawer, 'Asset Drawer')
	native_dock = EditorInterface.get_file_system_dock()
	
	await get_tree().process_frame
	
	if hide_native:
		remove_control_from_docks(native_dock)
	dock_children = native_dock.get_children()
	
	#Engine.register_singleton('YAFTheme', load('res://addons/yet_another_files/assets/yaf_theme.gd'))
	add_autoload_singleton('YAFTheme', 'res://addons/yet_another_files/assets/yaf_theme.gd')
	


func _exit_tree() -> void:
	if bottom:
		remove_control_from_bottom_panel(drawer)
	drawer.queue_free()
	if hide_native:
		add_control_to_dock(native_dock_layout, native_dock)
	#Engine.unregister_singleton('YAFTheme')
	remove_autoload_singleton('YAFTheme')


func _set_window_layout(configuration: ConfigFile) -> void:
	if configuration.has_section('yet_another_files'):
		pass


func _make_visible(visible: bool) -> void:
	if !visible and !bottom:
		bottom = true
		EditorInterface.get_editor_main_screen().remove_child(drawer)
		add_control_to_bottom_panel(drawer, 'Content')
		return
		
	if visible and bottom:
		bottom = false
		remove_control_from_bottom_panel(drawer)
		EditorInterface.get_editor_main_screen().add_child(drawer)
		drawer.show()
	
	if visible and !bottom:
		if drawer.get_node_or_null(^'%ContentField'):
			drawer.get_node(^'%ContentField').grab_focus()


func create_new(id: EDockID):
	dock_children[id].popup_centered()
	if id == EDockID.NEW_FOLDER:
		dock_children[id].get_child(0).get_child(1).emit_signal('text_changed', '')
		dock_children[id].get_child(0).get_child(1).grab_focus()
	if id == EDockID.NEW_SCENE:
		dock_children[id].get_child(1).get_child(0).get_child(-3).get_child(0).emit_signal('text_changed', '')
		dock_children[id].get_child(1).get_child(0).get_child(-3).get_child(0).grab_focus()
	# For RESOURCE i'll make my own implementation.
	# SCRIPT - done.


func init_configuration():
	if !DirAccess.dir_exists_absolute('res://.yafcfg'):
		DirAccess.make_dir_absolute('res://.yafcfg')
	if !FileAccess.file_exists( 'res://.yafcfg/folder_colors.res' ):
		var data := PackedDataContainer.new()
		data.pack({&'history': []})
		ResourceSaver.save(data, 'res://.yafcfg/folder_colors.res')
	if OWN_FAVS:
		if !FileAccess.file_exists( 'res://.yafcfg/favorites.res' ):
			var data := PackedDataContainer.new()
			data.pack([])
			ResourceSaver.save(data, 'res://.yafcfg/favorites.res')
	filesystem.scan()
	filesystem.scan_sources()


func config_favorites(action: StringName, path = null):
	var result = { 'value': null, 'error_code': OK }
	var favs_packed = load('res://.yafcfg/favorites.res') as PackedDataContainer
	var favorites = []
	for i in favs_packed:
		favorites.append(i)
	match action:
		&'add':
			if path not in favorites:
				favorites.append(path)
			else:
				result.error_code = ERR_ALREADY_EXISTS
		&'check':
			result.value = path in favorites
		&'remove':
			if path in favorites:
				favorites.erase(path)
			else:
				result.error_code = ERR_UNAVAILABLE
		&'get':
			result.value = favorites
		&'clear':
			favorites = []
		&'init':
			favorites = EditorInterface.get_editor_settings().get_favorites()
			result.value = favorites
		_:
			result.error_code = ERR_SKIP
	if result.error_code == OK:
		favs_packed.pack(favorites)
	return result


func config_folder_colors(action: StringName, path = '', color = null):
	var result = { 'value': null, 'error_code': OK }
	var cols_packed = load('res://.yafcfg/folder_colors.res') as PackedDataContainer
	var colors = {}
	var path_hash = String.num_uint64(path.hash())
	const HIST_SIZE = 10
	for key in cols_packed:
		colors[key] = cols_packed[key]
	
	var history = []
	if colors.history:
		for col in colors.history:
			history.push_back(col)
	
	var add_to_history = ''
	
	match action:
		&'set':
			colors[ path_hash ] = StringName( color.to_html() )
			add_to_history = colors[ path_hash ]
		&'add':
			if path_hash not in colors:
				colors[ path_hash ] = StringName( color.to_html() )
				add_to_history = colors[ path_hash ]
			else:
				result.value = Color.html( colors[path_hash] )
				result.error_code = ERR_ALREADY_EXISTS
		&'change':
			if path_hash in colors:
				colors[ path_hash ] = color
				add_to_history = colors[ path_hash ]
			else:
				result.error_code = ERR_UNAVAILABLE
		&'reset':
			if path_hash in colors:
				colors.erase( path_hash )
			else:
				result.error_code = ERR_UNAVAILABLE
		&'check':
			result.value = path_hash in colors
			result.error_code = ERR_SKIP
		&'get':
			if path_hash in colors:
				result.value = Color.html( colors[path_hash] )
				result.error_code = ERR_SKIP
			else:
				result.value = color
				result.error_code = ERR_UNAVAILABLE
		&'clear':
			colors.clear()
		&'get_history':
			result.value = history
			result.error_code = ERR_SKIP
		&'clear_history':
			history = []
		_:
			result.error_code = ERR_INVALID_PARAMETER
	
	if add_to_history:
		if history.has(add_to_history):
			history.erase(add_to_history)
		history.push_front(add_to_history)
		history = history.slice(0, HIST_SIZE)
	
	if result.error_code == OK:
		colors.history = history
		cols_packed.pack( colors )
		ResourceSaver.save(cols_packed, 'res://.yafcfg/folder_colors.res')
	if result.error_code == ERR_SKIP: result.error_code = OK
	return result
