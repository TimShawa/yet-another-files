@tool
extends PanelContainer
class_name ThumbnailPanel

@onready var preview: TextureRect = $Preview

@export var round_top_left := true:
	set(value):
		round_top_left = value
		preview.material.set_shader_parameter('rounded_corner_top_left', value)
		var style = get_theme_stylebox('panel', 'PanelContainer') as StyleBoxFlat
		radius = radius


@export var round_top_right := true:
	set(value):
		round_top_right = value
		preview.material.set_shader_parameter('rounded_corner_top_right', value)
		var style = get_theme_stylebox('panel', 'PanelContainer') as StyleBoxFlat
		radius = radius


@export var round_bottom_right := true:
	set(value):
		round_bottom_right = value
		preview.material.set_shader_parameter('rounded_corner_bottom_right', value)
		var style = get_theme_stylebox('panel', 'PanelContainer') as StyleBoxFlat
		radius = radius


@export var round_bottom_left := true:
	set(value):
		round_bottom_left = value
		preview.material.set_shader_parameter('rounded_corner_bottom_left', value)
		var style = get_theme_stylebox('panel', 'PanelContainer') as StyleBoxFlat
		radius = radius


@export var radius := 7:
	set(value):
		radius = max(value, 0)
		var stylebox = get_theme_stylebox('panel', 'PanelContainer') as StyleBoxFlat
		stylebox.corner_radius_top_left = radius * int(round_top_left)
		stylebox.corner_radius_top_right = radius * int(round_top_right)
		stylebox.corner_radius_bottom_left = radius * int(round_bottom_left)
		stylebox.corner_radius_bottom_right = radius * int(round_bottom_right)
		preview.material.set_shader_parameter( 'radius_scale', 1 / min(size.x, size.y) * 2 * clampi(radius, 0, min(size.x, size.y) / 2) )


var texture := Texture2D.new():
	set(value):
		texture = value
		preview.texture = texture
