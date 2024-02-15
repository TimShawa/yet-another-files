@tool
extends Node

signal finished(file)

@onready var win_select_parent: Window = $WinSelectParent
@onready var win_configure: Window = $WinConfigure
@onready var tree: Tree = $WinSelectParent/PanelContainer/VBoxContainer2/VBoxContainer/PanelContainer2/VBoxContainer/Tree
var class_list: Array[StringName] = []
var base_class := &'Object'
var extend_type := &'Node':
	set(value):
		extend_type = value
		%'BtnExtend/../Label'.text = 'Selected: ' + value
var location: String = 'res://'

var quick_classes := {
	&'Object': null,
	&'Resource': null,
	&'Node': null,
	
	&'Node2D': null,
	&'CharacterBody2D': null,
	&'StaticBody2D': null,
	&'RigidBody2D': null,
	
	&'Node3D': null,
	&'CharacterBody3D': null,
	&'StaticBody3D': null,
	&'RigidBody3D': null,
	
	&'Control': null,
	&'Panel': null,
	&'Button': null,
	&'Window': null
}


func request_create(path: String) -> Array[String]:
	location = path.trim_prefix('/') + '/'
	win_select_parent.popup_centered()
	var answer = await finished
	if finished:
		var text := ''
		text += 'extends ' + extend_type + '\n'
		if new_class:
			text += 'class_name ' + new_class + '\n'
		return [ path, text ]
	return []


func _on_win_select_parent_about_to_popup() -> void:
	update_tree()


func update_tree():
	tree.clear()
	
	var classes_packed := ClassDB.get_inheriters_from_class(base_class)
	class_list.clear()
	for i in classes_packed:
		if i not in [ &'RefCounted', &'Node' ]:
			class_list.append(StringName(i))
	class_list.sort_custom(func(a: StringName, b: StringName): return a.naturalnocasecmp_to(b) == -1)	
	var root = tree.create_item()
	root.set_text(0, 'Object')
	root.set_icon(0, EditorInterface.get_editor_theme().get_icon(&'Object', &'EditorIcons'))
	_add_item(&'RefCounted')
	_add_item(&'Node')
	_add_item(base_class, root, true)
	quick_classes.Object = root
	await get_tree().physics_frame
	root.set_collapsed_recursive(true)
	root.uncollapse_tree()
	tree.set_selected(root.get_child(1), 0)
	
	for node: Control in %QuickBases.get_children():
		node.visible = !_should_hide_class(node.name)


func _add_item(type: StringName, parent = null, skip := false):
	if _should_hide_class(type): return
	var p: TreeItem
	if !skip:
		p = tree.create_item(parent)
		var theme := EditorInterface.get_editor_theme()
		p.set_text(0, type)
		if theme.has_icon(type, &'EditorIcons'):
			p.set_icon(0, theme.get_icon(type, &'EditorIcons'))
		else:
			p.set_icon(0, theme.get_icon(&'Object', &'EditorIcons'))
		if type in quick_classes:
			quick_classes[type] = p
	for i in class_list:
		if ClassDB.get_parent_class(i) == type:
			_add_item(i, p if !skip else parent)


func _on_win_select_parent_close_requested() -> void:
	win_select_parent.hide()
	tree.clear()


func _should_hide_class(type: StringName):
	var features := EditorFeatureProfile.new()
	features.load_from_file(EditorInterface.get_current_feature_profile())
	if features.is_class_disabled(type): return true
	if ClassDB.is_parent_class(type, &'Node') and type.begins_with(&'Editor'): return true
	if !ClassDB.is_class_enabled(type): return true
	if !ClassDB.can_instantiate(type) and !ClassDB.get_inheriters_from_class(type).size(): return true
	if !ClassDB.is_parent_class(type, base_class): return true
	return false


func _on_tree_item_selected() -> void:
	self.extend_type = tree.get_selected().get_text(0)


func _on_quick_class_pressed(type: StringName):
	tree.set_selected(quick_classes[type], 0)
	_on_btn_extend_pressed()


func _on_btn_extend_pressed() -> void:
	win_select_parent.hide()
	reset_configure_win()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	win_configure.popup_centered()
	#win_configure.position = Vector2i(EditorInterface.get_editor_main_screen().size / 2 * EditorInterface.get_editor_scale())


var file_name: String = 'new_script.gd'
var new_class: StringName = &''

# update | reset | clear
func reset_configure_win(): # fill window based on extend_type
	var win := win_configure as Window
	win.title = 'Create script extends <' + extend_type + '>'
	%PreviewExtends.text = extend_type
	_on_l_file_name_text_changed('new_script.gd')
	_on_l_class_name_text_changed('')


func clear_configure_win():
	var win = win_configure as Window
	win.title = 'Create script dialog'
	%LFileName.text = ''
	%LClassName.text = ''
	%LScriptIcon.text = ''
	%PreviewIcon.texture = Texture2D.new()
	%PreviewName.text = ''
	%PreviewExtends.text = ''
	%PreviewLocation.text = ''


func _on_l_class_name_text_changed(new_text: String) -> void:
	new_class = StringName(new_text)
	if new_text.is_empty():
		%PreviewName.text = '"' + file_name.get_file() + '"'
	else:
		%PreviewName.text = new_class
	#$WinConfigure/PanelContainer3/VBoxContainer.reset_size()


func _on_l_file_name_text_changed(new_text: String) -> void:
	file_name = new_text.trim_prefix('/')
	if file_name.is_empty() or !file_name.begins_with('res://'):
		%PreviewLocation.text = location.path_join(file_name)
	else:
		%PreviewLocation.text = file_name


func _on_win_configure_close_requested() -> void:
	win_configure.hide()
	clear_configure_win()


func _on_v_box_container_resized() -> void:
	if win_configure:
		var size = $WinConfigure/PanelContainer3/VBoxContainer.size
		$WinConfigure/PanelContainer3.size = size
		win_configure.size = size


func _on_btn_confirm_pressed() -> void:
	_on_win_configure_close_requested()
	
	var path := file_name if file_name.is_absolute_path() else location.path_join(file_name)
	
	finished.emit(path)
