@tool
extends HBoxContainer
class_name PathListEntry

signal child_selected(path)
var is_root := false

var subdirs: PackedStringArray = []:
	set(value):
		subdirs = value
		var popup: PopupMenu = $PopupMenu
		for subdir in subdirs:
			popup.add_item(subdir.split('/',0)[-1])
		popup.reset_size()


var path: String = '':
	set(value):
		path = value
		var text := path.split('/',0)[-1]
		if text.ends_with(':'):
			text = '/'
		$BtnDirectory.text = text
		subdirs = DirAccess.get_directories_at(path)


func connect_drawer(drawer: Control):
	$BtnDirectory.connect('pressed', func(p_drawer = drawer, p_path = path):
		drawer.change_dir(p_path))
	$PopupMenu.connect('index_pressed', func(p_idx, p_drawer = drawer, p_path = path, p_subdirs = subdirs):
		drawer.change_dir(path.path_join(p_subdirs[p_idx])))


func _on_btn_popup_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if !event.is_echo() and !event.pressed:
				$PopupMenu.position = $BtnPopup.global_position + $BtnPopup.size * Vector2(0,1)
				$PopupMenu.show()
