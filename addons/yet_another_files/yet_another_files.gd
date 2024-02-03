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
	
	init_configuration()


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
		data.pack({})
		ResourceSaver.save(data, 'res://.yafcfg/favorites.res')
	if OWN_FAVS:
		if !FileAccess.file_exists( 'res://.yafcfg/favorites.res' ):
			var data := PackedDataContainer.new()
			data.pack({})
			ResourceSaver.save(data, 'res://.yafcfg/favorites.res')
	filesystem.scan()


func config_favorites(action: StringName, arg = null):
	var favs_packed = load('res://.yafcfg/favorites.res') as PackedDataContainer
	var favorites = []
	for i in favs_packed:
		favorites.append(i)
	match action:
		&'add':
			if arg not in favorites:
				favorites.append(arg)
				return true
			return ERR_ALREADY_EXISTS
		&'contains':
			return arg in favorites
		&'remove':
			if arg in favorites:
				favorites.erase(arg)
			return ERR_UNAVAILABLE
		&'get':
			return favorites
		&'set':
			favorites = arg
			favs_packed.pack(favorites)
		&'clear':
			favorites = []
		&'init':
			favorites = EditorInterface.get_editor_settings().get_favorites()
		_:
			return ERR_SKIP
	favs_packed.pack(favorites)
	return OK


func _save_external_data() -> void: pass


func reset_folder_color(dir) -> void:
	var colors_packed := load('res://.yafcfg/folder_colors.res') as PackedDataContainer
	var dir_hash := String.num_uint64(dir.hash())
	var folder_colors: Dictionary
	for key in colors_packed:
		folder_colors[key] = colors_packed[key]
	if dir_hash in folder_colors:
		folder_colors.erase(dir_hash)
	colors_packed.pack(folder_colors)


func save_folder_color(dir: String, color: Color) -> void:
	var colors_packed := load('res://.yafcfg/folder_colors.res') as PackedDataContainer
	var dir_hash := String.num_uint64(dir.hash())
	var folder_colors: Dictionary
	for key in colors_packed:
		folder_colors[key] = colors_packed[key]
	folder_colors[ dir_hash ] = color.to_html(0)
	colors_packed.pack(folder_colors)


func load_folder_color(dir: String) -> Color:
	var colors_packed := load('res://.yafcfg/folder_colors.res') as PackedDataContainer
	var dir_hash = String.num_uint64(dir.hash())
	var found := false
	for key in colors_packed:
		if key == dir_hash:
			found = true
			break
	if found:
		return Color.html( colors_packed[ dir_hash ] )
	return Color.GRAY


static func get_file_preview(path: String, file: DirContentItem):
	EditorInterface.get_resource_previewer().queue_resource_preview(path, file, 'set_icon_preview', null)
