@tool
extends GridContainer

var show_as_tree := false

func _enter_tree() -> void:
	await get_tree().process_frame
	connect('child_entered_tree', connect_item)
	connect('child_exiting_tree', disconnect_item)

func connect_item(item: DirContentItem):
	EditorInterface.get_file_system_dock().get_method_list()
	item.connect('rmb_selected', _item_selected)
func disconnect_item(item: DirContentItem):
	EditorInterface.get_file_system_dock().get_method_list()


func _item_selected(path: String): pass
	#print(EditorInterface.get_selected_paths())
	#EditorInterface.get_file_system_dock().call_deferred('_tree_rmb_select')
