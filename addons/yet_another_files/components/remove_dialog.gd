@tool
extends Window
class_name RemoveDialog

signal button_pressed(button)

@export var tree: Tree
@export var list: ItemList
@export var picker_container: MarginContainer
var picker: EditorResourcePicker
var referencers: PackedStringArray

func _ready():
	tree.clear()
	tree.create_item()
	list.clear()
	if !picker_container.get_child_count():
		picker = EditorResourcePicker.new()
		picker.base_type = 'Resource'
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.size_flags_vertical = Control.SIZE_EXPAND_FILL
		picker_container.add_child(picker)
	tree.set_column_title(0, 'Asset')
	tree.set_column_title(1, 'Class')
	tree.set_column_title(2, 'Asset Referencers')
	tree.set_column_title(3, 'Memory References')
	for i in tree.columns:
		tree.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)


func close_window() -> void:
	hide()
	tree.clear()
	list.clear()


func request_delete(assets: PackedStringArray):
	fill_pending(assets)
	for i in assets:
		fill_referencers(i)
	for i in referencers:
		list.add_item(i)
	var mode = referencers.size()
	$Panel/VBox/Referencers.visible = mode
	$Panel/VBox/Bottom/HBox/VBox.visible = mode
	$Panel/VBox/Bottom/HBox/VBox2.visible = mode
	$Panel/VBox/Bottom/HBox/VBox3.visible = !mode
	popup_centered_ratio(0.8)
	match await button_pressed:
		'cancel':
			close_window()
		'delete':
			delete_assets(assets)
		'replace':
			replace_dependencies(assets, picker.edited_resource.resource_path \
				if picker.edited_resource
				else '')


func fill_pending(paths: PackedStringArray):
	for path in paths:
		var asset = tree.get_root().create_child()
		var type = EditorInterface.get_resource_filesystem().get_file_type(path)
		if path.ends_with('/'):
			asset.set_text(0, path.split('/', 0)[-1] + '/')
			type = &'Folder'
		else:
			asset.set_text(0, path.get_file())
			if type.is_empty():
				type = &'File'
		asset.set_text(1, type)


func fill_referencers(path, folder = EditorInterface.get_resource_filesystem().get_filesystem_path('res://')):
	if !folder: return
	for i in folder.get_subdir_count():
		fill_referencers(path, folder.get_subdir(i))
	for i in folder.get_file_count():
		var found = false
		var file = folder.get_file_path(i)
		for dep in ResourceLoader.get_dependencies(file):
			if dep.split('::')[-1] == path:
				found = true
				break
		if found:
			if folder.get_file(i) not in referencers:
				referencers.push_back(folder.get_file(i))


func replace_dependencies(paths: PackedStringArray, resource):
	for own in referencers:
		for dep in paths:
			DependencyEditor.static_rename(own, dep, resource)
	delete_assets(paths)


func delete_assets(paths: PackedStringArray):
	for i in paths:
		DirAccess.remove_absolute(i)
		if FileAccess.file_exists(i + '.import'):
			DirAccess.remove_absolute(i + '.import')
	print('Done.')


func _button_pressed(button):
	emit_signal('button_pressed', button)
