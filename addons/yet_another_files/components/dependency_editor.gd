@tool
extends Window
class_name DependencyEditor

@onready var dep_graph: GraphEdit = $Panel/VBox/Panel/DepGraph
var dependencies: Array[Dictionary] = []
var owners = []


func edit(path):
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
	for own in owners:
		dep_graph.add_owner(own.path, own.type)
	popup_centered()


func close_window() -> void:
	hide()
	dep_graph.clear_connections()
	for node in dep_graph.get_children():
		dep_graph.remove_child(node)
		node = null
	dep_graph.dependencies.clear()
	dep_graph.owners.clear()


func _on_window_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if !event.is_echo() and !event.pressed:
			if event.get_keycode_with_modifiers() == KEY_ESCAPE:
				close_window()


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
