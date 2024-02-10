@tool
extends GraphNode
class_name DepGraphElement


signal title_ready

const SCENE = preload('res://addons/yet_another_files/components/dep_graph_element.scn')
var b_title_ready = false:
	set(value):
		b_title_ready = true
		if b_title_ready:
			emit_signal('title_ready')
var title_label: Label
var type_label: Label
var type_icon: TextureRect
var height = 215
var path: String


const DEPENDENCY = -1
const EDITED = 0
const OWNER = 1


func _ready() -> void:
	get_theme_stylebox('panel_selected', 'GraphNode').border_color = Color(EditorInterface.get_editor_theme().get_color('highlight_color', 'Editor'), 1)
	get_theme_stylebox('titlebar_selected', 'GraphNode').border_color = Color(EditorInterface.get_editor_theme().get_color('highlight_color', 'Editor'), 1)
	if !b_title_ready:
		var hbox = get_titlebar_hbox()
		type_icon = TextureRect.new()
		var vbox = VBoxContainer.new()
		title_label = Label.new()
		type_label = Label.new()
		
		hbox.get_child(0).free()
		#hbox.custom_minimum_size.y = 100
		hbox.add_child(type_icon)
		hbox.add_child(vbox)
		vbox.add_child(title_label)
		vbox.add_child(type_label)
		
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override('separation', 0)
		
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.label_settings = LabelSettings.new()
		title_label.label_settings.shadow_color = Color.BLACK
		
		type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		type_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		type_label.label_settings = LabelSettings.new()
		
		type_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		type_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		type_icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		type_icon.custom_minimum_size.x = 50
		type_icon.reset_size()
		type_icon.texture = load('res://addons/yet_another_files/assets/icons/svg/icon_resource.svg')
		
		b_title_ready = true


func configure(depend: int, path: String, type: StringName):
	name = path.get_file().get_basename().to_pascal_case() + '_' + path.get_extension().to_upper()
	if !b_title_ready:
		await title_ready
	title_label.text = path.get_file()
	type_label.text = type
	type_icon.texture = YAFTheme.get_file_icon(path, type)
	self.path = path
	
	match depend:
		DEPENDENCY:
			set_slot_enabled_left(0, 0)
			set_slot_enabled_right(0, 1)
		EDITED:
			set_slot_enabled_left(0, 1)
			set_slot_enabled_right(0, 1)
		OWNER:
			set_slot_enabled_left(0, 1)
			set_slot_enabled_right(0, 0)
	
	var color = YAFTheme.get_file_color(path, type)
	set_slot_color_left(0, color)
	set_slot_color_right(0, color)
	get_theme_stylebox('titlebar', 'GraphNode').bg_color = color.darkened(0.4)
	get_theme_stylebox('titlebar', 'GraphNode').border_color = color.darkened(0.4)
	get_theme_stylebox('titlebar_selected', 'GraphNode').bg_color = color.darkened(0.4)
	get_theme_stylebox('panel', 'GraphNode').border_color = color.darkened(0.4)
	type_label.label_settings.font_color = color.lightened(0.6)
	
	if type not in [ &'GDScript' ]:
		type_icon.self_modulate = color
	if has_preview(path, type):
		EditorInterface.get_resource_previewer().queue_resource_preview(path, self, 'set_preview', color)
	else:
		EditorInterface.get_resource_previewer().queue_resource_preview('', self, 'set_preview', color)


func set_preview(path: String, preview: Texture2D, thumbnail: Texture2D, color: Color):
	if preview:
		%Preview.texture = preview
		$HBox/Ratio.show()
	else:
		$HBox/Ratio.hide()
		get_theme_stylebox('panel', 'GraphNode').bg_color = color.darkened(0.6)


func has_preview(file, type) -> bool:
	if FileAccess.file_exists(file):
		for i in [ &'Texture' ]:
			if ClassDB.is_parent_class(type, i):
				return true
	return false


# open on double-click
func request_rename(): pass


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			if !event.is_echo() and event.pressed:
				if event.double_click:
					request_rename()
