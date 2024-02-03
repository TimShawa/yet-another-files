@tool
extends Window


signal pressed(confirmed: bool)


var path := '':
	set(value):
		path = value
		title = 'Duplicating ' + ('file: ' if !path.ends_with('/') else 'folder: ') + path.get_file()
		%EditName.text = path.split('/')[-1]
		%EditName.placeholder_text = path.split('/')[-1]


func _ready() -> void:
	_on_size_changed()
	var popup := $FileExist as AcceptDialog
	popup.add_button('Copy Text', true)
	popup.custom_action.connect( func(p_popup := popup): 
		DisplayServer.clipboard_set(p_popup.dialog_text)
	)


func _on_size_changed() -> void: pass


func request_duplicate(path) -> String:
	self.path = path
	popup_centered(min_size)
	%EditName.grab_focus()
	if %EditName.text.rfind('.') > 0:
		%EditName.select(0, (%EditName.text as String).rfind('.'))
	else:
		%EditName.select_all()
	var return_value: String
	if await pressed:
		if %EditName.text:
			var new_path = path.get_base_dir().path_join(%EditName.text)
			if path.ends_with('/'):
				if DirAccess.dir_exists_absolute(new_path):
					$FileExist.popup_centered()
				else:
					return_value = %EditName.text
			else:
				if FileAccess.file_exists(new_path):
					$FileExist.popup_centered()
				else:
					return_value = %EditName.text
	hide()
	return return_value


func _on_btn_pressed(confirmed: bool):
	emit_signal('pressed', confirmed)
