@tool
extends ConfirmationDialog

signal changed

var filename := '.gitignore':
	set(value):
		filename = value
		update_text()
var location := 'res://':
	set(value):
		location = value
		update_text()
const TEXT: String = 'File {filename} already exist in current location ({location}).
Select action:'
var state: String = 'standby'


func _ready() -> void:
	add_button('Overwrite', 1, 'overwrite')


func update_text():
	self.text = TEXT.format(filename, location)


func _state_changed(state: String):
	match state:
		'cancel':
			self.state = 'canceled'
		'ignore':
			self.state = 'ignored'
		'overwrite':
			self.state = 'overwritten'
	changed.emit()


func reset():
	state = 'standby'
	if visible:
		hide()
