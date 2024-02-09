@tool
extends Node
class_name YAFTheme

const DYNAMIC_BG = false
const BLIND = 0.2
const BG_OPACITY = 0.3

static func get_file_type(file_type) -> StringName:
	if !ClassDB.class_exists(file_type):
		if file_type in [ &'File', &'TextFile' ]:
			return file_type
	while ClassDB.is_parent_class(file_type, 'RefCounted'):
		if file_type in file_types:
			break
		file_type = ClassDB.get_parent_class(file_type)
	return file_type


static func get_file_icon(path: String, imported_type: StringName = &'Resource') -> Texture2D:
	var file_type: StringName = get_file_type(imported_type)
	if &'icon' not in file_types[ file_type ]:
		return load(file_types.Resource.icon)
	var icon = file_types[ file_type ].icon
	if icon is String:
		if icon.begins_with('editor://'):
			icon = icon.trim_prefix('editor://').split('/')
			icon = EditorInterface.get_editor_theme().get_icon(icon[1], icon[0])
		else:
			if icon.begins_with('type://'):
				file_type = get_cyclesafe_ref('icon', icon)
			icon = load(file_types[ file_type ].icon)
	return icon


static func get_file_color(path: String, imported_type: StringName = &'Resource') -> Color:
	var file_type: StringName = get_file_type(imported_type)
	if 'color' not in file_types[ file_type ]:
		return file_types.Resource.color
	var color = file_types[file_type].color
	if color is String and color.begins_with('type://'):
		file_type = get_cyclesafe_ref('color', color)
	color = file_types[ file_type ].color
	return color


static func get_file_background(path: String, imported_type: StringName = &'Resource') -> Color:
	var file_type: StringName = get_file_type(imported_type)
	var tint
	var color = get_file_color(path, file_type)
	if !DYNAMIC_BG:
		return Color(color, BG_OPACITY).lightened(BLIND)
	if 'bg_colored' not in file_types[ file_type ]:
		return Color(color, file_types.Resource.bg_colored).lightened(BLIND)
	else:
		tint = file_types[ file_type ].bg_colored
		if tint is String and tint.begins_with('type://'):
			file_type = get_cyclesafe_ref('bg_colored', tint)
		tint = file_types[ file_type ].bg_colored
	color = Color(color, tint)
	return color.lightened(BLIND)


static func get_cyclesafe_ref(field: StringName, reference: String, max_steps = 100) -> StringName:
	reference = reference.trim_prefix('type://')
	var types := []
	for i in max_steps:
		var value = file_types[ reference ][ field ]
		if value is String:
			if value.is_empty():
				break
			if value.begins_with('type://'):
				value = value.trim_prefix('type://')
				if value not in types:
					types.append(value)
					reference = value
					continue
		return reference.trim_prefix('type://')
	return &'Resource'


const file_types := {
	'File': {
		#'color': Color(0.4314, 0.4314, 0.4314, 1),
		'color': 'type://Resource',
		'bg_colored': 0.0,
		'icon': 'res://addons/yet_another_files/assets/icons/icon_file_blank.png'
	},
	'TextFile': {
		'color': 'type://File'
	},
	'Resource': {
		'color': Color(1, 1, 1, 1),
		'bg_colored': 0.1,
		'icon': 'res://addons/yet_another_files/assets/icons/svg/icon_resource.svg'
	},
	'GDScript': {
		'color': Color(0, 0.5411, 1, 1),
		'bg_colored': 0.2,
		'icon': 'res://addons/yet_another_files/assets/icons/icon_file_gdscript.png'
	},
	'Texture2D': {
		'color': Color.BROWN,
		'icon': 'res://addons/yet_another_files/assets/icons/svg/icon_image_texture.svg'
	},
	'Image': {
		'color': 'type://Texture2D',
		'icon': 'type://Texture2D'
	},
	'PackedScene': {
		'color': Color(1, 0.6094, 0, 1)
	},
	'Mesh': {
		'color' = Color.YELLOW
	},
	'Shape2D': {
		'color' = Color.DEEP_SKY_BLUE
	},
	'Shape3D': {
		'color': 'type://Shape2D'
	},
	'Animation': {
		'color': Color(0.2532, 0.3828, 0.2532, 1)
	},
	'AnimationLibrary': {
		'color': 'type://Animation'
	},
	'Material': {
		'color': Color.LIME_GREEN
	},
	'Curve': {
		'color': Color.BLUE_VIOLET,
		'bg_colored': 0.2
	},
	'Curve2D': {
		'color': 'type://Curve'
	},
	'Curve3D': {
		'color': 'type://Curve'
	},
	
}


func _get_property_list() -> Array[Dictionary]:
	return [{
		'name': 'file_types',
		'type': TYPE_DICTIONARY,
		'usage': PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR
	}]
