@tool
extends PanelContainer
class_name DependencyEditor


const SCENE = preload('res://addons/yet_another_files/components/dependency_editor.scn')
var plugin: ContentManagerPlugin
@onready var dep_graph: GraphEdit = $Panel/VBox/Panel/DepGraph
var dependencies: Array[Dictionary] = []
var owners: Array[Dictionary] = []
var edited = ''


func edit(path):
	edited = path
	await dep_graph.clean()
	var type = EditorInterface.get_resource_filesystem().get_file_type(path)
	if type.is_empty():
		type = &'File'
	dep_graph.set_edited(path, type)
	dependencies.clear()
	fill_dependencies(path, type)
	owners.clear()
	fill_owners(path, type)
	for dep in dependencies:
		dep_graph.add_dependency(dep.path, dep.type)
	dep_graph.align_dependencies()
	for own in owners:
		dep_graph.add_owner(own.path, own.type)
	dep_graph.align_owners()


func close_window() -> void:
	plugin.close_deps_editor()


func fill_dependencies(path, type):
	for i in ResourceLoader.get_dependencies(path):
		var p = i.split('::')[-1]
		var t = EditorInterface.get_resource_filesystem().get_file_type(p)
		dependencies.append({ 'path': p, 'type': t })


func fill_owners(path, type, folder = EditorInterface.get_resource_filesystem().get_filesystem_path('res://')):
	if !folder: return
	for i in folder.get_subdir_count():
		fill_owners(path, type, folder.get_subdir(i))
	for i in folder.get_file_count():
		var found = false
		var file = folder.get_file_path(i)
		for dep in ResourceLoader.get_dependencies(file):
			if dep.split('::')[-1] == path:
				found = true
				break
		if found:
			type = EditorInterface.get_resource_filesystem().get_file_type(file)
			if type.is_empty():
				type = &'File'
			owners.append({ 'path': file, 'type': type })


func _on_dep_rename_requested(dep):
	var dialog = EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.current_dir = dep.get_base_dir()
	get_tree().root.add_child(dialog)
	dialog.connect('file_selected', rename_dependency.bind(dep))
	dialog.popup_centered_ratio(0.6)
	await dialog.visibility_changed
	dialog.queue_free()
	dialog = null


func rename_dependency(rename, dependency):
	print('Renaming "', dependency, '" to "', rename, '"...')
	static_rename(edited, rename, dependency)
	close_window()
	plugin.open_deps_editor(edited)
	print('Done.')


static func static_rename(edited, rename, dependency):
	var res = load(edited) as Resource
	if res is PackedScene:
		var bundle = res.get('_bundled').variants
		for i in bundle.size():
			if bundle[i] is Resource:
				if bundle[i].resource_path.split('::').size() == 1:
					if bundle[i].resource_path == dependency:
						bundle[i] = load(rename)
		res.set_indexed(^'_bundled:variant', bundle)
	for i in res.get_property_list():
		if res.get(i.name) is Resource:
			print(res.get(i.name).resource_path)
			if res.get(i.name).resource_path == dependency:
				res.set(i.name, load(rename))
	ResourceSaver.save(res)
	EditorInterface.get_resource_filesystem().update_file(edited)


func recurse_dict(dict: Dictionary, value: Variant, prefix: StringName = &''):
	printt('edited', value)
	for i in dict:
		if typeof(dict[i]) == typeof(value):
			printt(i, dict[i])
			if dict[i] == value:
				print(prefix + i)
		if dict[i] is Dictionary:
			recurse_dict(dict[i], value, i + '.')
