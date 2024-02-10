@tool
extends GraphEdit

var edited: DepGraphElement
var dependencies: Array[DepGraphElement]
var owners: Array[DepGraphElement]
var separation := Vector2(700, 100)

func _is_in_input_hotzone(in_node: Object, in_port: int, mouse_position: Vector2) -> bool:
	return false
func _is_in_output_hotzone(in_node: Object, in_port: int, mouse_position: Vector2) -> bool:
	return false


func set_edited(path: String, type: StringName):
	edited = DepGraphElement.SCENE.instantiate()
	add_child(edited)
	edited.configure(DepGraphElement.EDITED, path, type)


func add_dependency(path, type):
	var dep: DepGraphElement = DepGraphElement.SCENE.instantiate()
	add_child(dep)
	dep.configure(dep.DEPENDENCY, path, type)
	dependencies.push_back(dep)
	dep.position_offset.x = -separation.x
	var height = dep.height
	connect_node(dep.name, 0, edited.name, 0)
	if dependencies.size() > 1:
		dep.position_offset.y = dependencies[-2].position_offset.y + dependencies[-2].size.y + separation.y


func add_owner(path, type):
	var own: DepGraphElement = DepGraphElement.SCENE.instantiate()
	add_child(own)
	own.configure(own.OWNER, path, type)
	owners.push_back(own)
	own.position_offset.x = separation.x
	connect_node(edited.name, 0, own.name, 0)
	if owners.size() > 1:
		own.position_offset.y = owners[-2].position_offset.y + owners[-2].size.y + separation.y


func align_dependencies():
	if dependencies.is_empty():
		return
	var start = dependencies[0].position_offset.y
	var end = dependencies[-1].position_offset.y + dependencies[-1].size.y
	var center = edited.position_offset.y + edited.size.y / 2
	var offset = (start + end) / 2 - center
	for dep in dependencies:
		dep.position_offset.y -= offset


func align_owners():
	if owners.is_empty():
		return
	var start = owners[0].position_offset.y
	var end = owners[-1].position_offset.y + owners[-1].size.y
	var center = edited.position_offset.y + edited.size.y / 2
	var offset = (start + end) / 2 - center
	for own in owners:
		own.position_offset.y -= offset


func clean():
	clear_connections()
	for i in get_children():
		remove_child(i)
		i.free()
	edited = null
	dependencies.clear()
	owners.clear()
	await get_tree().process_frame
