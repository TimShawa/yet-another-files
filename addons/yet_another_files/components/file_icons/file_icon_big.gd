@tool
extends DirContentItem

@export_group('References')
@export var bg_panel: PanelContainer
@export var main_panel: PanelContainer
@export var file_panel: PanelContainer
@export var file_icon: TextureRect
@export var folder_panel: AspectRatioContainer
@export var filetype_label: Label
@export_group('')


func update_display() -> void:
	handheld_selector.visible = _is_handheld() and focus_mode == Control.FOCUS_NONE
	var stylebox = bg_panel.get_theme_stylebox('panel', 'PanelContainer') as StyleBoxFlat
	if !is_directory:
		if selection:
			if selection == 2:
				stylebox.bg_color = EditorInterface.get_editor_theme().get_color('accent_color', 'Editor')
			else:
				stylebox.bg_color = EditorInterface.get_editor_theme().get_color('highlight_color', 'Editor')
			filename_label.label_settings.font_color = Color.WHITE
			filetype_label.label_settings.font_color = (stylebox.bg_color * 1.6).clamp()
		else:
			stylebox.bg_color = Color(0.2392, 0.2392, 0.2392, 1)
			filename_label.label_settings.font_color = Color.SILVER
			filetype_label.label_settings.font_color = Color.DIM_GRAY
		stylebox.shadow_size = 5
		stylebox.shadow_offset = Vector2.ONE * 5
		main_panel.get_theme_stylebox('panel', 'PanelContainer').bg_color = Color.BLACK
		file_icon.texture = THEME.get_file_icon(path, file_type)
		file_panel.get_theme_stylebox('panel', 'PanelContainer').border_color = THEME.get_file_color(path, file_type)
		file_panel.get_theme_stylebox('panel', 'PanelContainer').bg_color = THEME.get_file_background(path, file_type)
	else:
		if selection:
			if selection == 2:
				stylebox.bg_color = EditorInterface.get_editor_theme().get_color('accent_color', 'Editor')
			else:
				stylebox.bg_color = EditorInterface.get_editor_theme().get_color('highlight_color', 'Editor')
			filename_label.label_settings.font_color = Color.WHITE
			stylebox.shadow_size = 5
			stylebox.shadow_offset = Vector2.ONE * 5
		else:
			stylebox.bg_color = Color.TRANSPARENT
			filename_label.label_settings.font_color = Color.SILVER
			stylebox.shadow_size = 0
			stylebox.shadow_offset = Vector2.ZERO
		main_panel.get_theme_stylebox('panel', 'PanelContainer').bg_color = Color.TRANSPARENT
		folder_panel.get_child(0).self_modulate = folder_color
	super()


func _on_focus_entered(): super()
func _on_handheld_selector_gui_input(event = null): super(event)


func set_icon_size(new_size):
	super(new_size)
	var S := EditorInterface.get_editor_scale()
	var font_size: int = EditorInterface.get_editor_settings().get_setting('interface/editor/main_font_size')
	var main_font: Font = EditorInterface.get_editor_theme().get_font('main', 'EditorFonts')
	var mono_font: Font = EditorInterface.get_editor_theme().get_font('main_msdf', 'EditorFonts')
	if main_panel:
		main_panel.custom_minimum_size.y = icon_size * S
	if filename_label:
		filename_label.label_settings.font_size = font_size * S
		filename_label.label_settings.font = main_font
	if filetype_label:
		filetype_label.label_settings.font_size = font_size * 0.8 * S
		filetype_label.label_settings.font = mono_font
