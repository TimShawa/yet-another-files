@tool
extends GraphEdit

var edited: DepGraphElement
var dependencies: Array[DepGraphElement]
var owners: Array[DepGraphElement]
@export var separation = 100.0

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
	dep.position_offset.x = -500
	var height = dep.size.y
	connect_node(dep.name, 0, edited.name, 0)
	for d in dependencies:
		d.position_offset.y = -(height * dependencies.size() / 2.0) \
			+ height * dependencies.find(d) \
			+ height / 2 \
			+ separation * (dependencies.find(d) - 1)


func add_owner(path, type):
	var own: DepGraphElement = DepGraphElement.SCENE.instantiate()
	add_child(own)
	own.configure(own.OWNER, path, type)
	owners.push_back(own)
	own.position_offset.x = 500
	var height = own.size.y
	connect_node(edited.name, 0, own.name, 0)
	for o in owners:
		o.position_offset.y = -(height * owners.size() / 2.0) \
			+ height * owners.find(o) \
			+ height / 2 \
			+ separation * (owners.find(o) - 1)
