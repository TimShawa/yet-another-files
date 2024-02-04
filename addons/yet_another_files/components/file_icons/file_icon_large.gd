@tool
extends "res://addons/yet_another_files/components/file_icons/file_icon_big.gd"


func update_display():
	super()
	file_icon.visible = !is_directory and THEME.get_file_icon(path, file_type) != THEME.get_file_icon(path, &'Resource')
	filetype_label.visible = file_type != &'File'
	if !is_directory and filetype_label.visible:
		var S := EditorInterface.get_editor_scale()
		var font_size: int =roundi( EditorInterface.get_editor_settings().get_setting('interface/editor/main_font_size') * S )
		filetype_label.label_settings.font_size = font_size * 2.5
		filetype_label.label_settings.font_color = THEME.get_file_color(path, file_type)
		filetype_label.self_modulate.a = THEME.BG_OPACITY * 0.4
		var ft_text: StringName = file_type.capitalize()
		var replacement = {
			&'A E S': &'AES',
			&'A Star': &'A-Star',
			&'1 D': &'1D',
			&'2 D': &'2D',
			&'3 D': &'3D',
			&'4 D': &'3D',
			&'E Q 6': &'EQ-6',
			&'E Q 12': &'EQ-12',
			&'E Q 21': &'EQ-21',
			&'E Q': &'EQ',
			&'M P 3': &'MP3',
			&'W A V': &'WAV',
			&'C P U': &'CPU',
			&'C S G': &'CSG',
			&'Char F X': &'CharFX',
			&'Class D B': &'ClassDB',
			&'Theme D B': &'ThemeDB',
			&'X Y Z': &'XYZ',
			&'D T L S': &'DTLS',
			&'E Net': &'E-Net',
			&'I O S': &'iOS',
			&'Linux B S D': &'LinuxBSD',
			&'Mac O S': &'MacOS',
			&'R P C': &'RPC',
			&'P C': &'PC',
			&'F B X': &'FBX',
			&'G L T F': &'GLTF',
			&'V C': &'VC',
			&'R I D': &'RID',
			&'UID': &'UID',
			&'I D': &'ID',
			&'G D Script': &'GDScript',
			&'S D F': &'SDF',
			&'6 D O F': &'6-DOF',
			&'H M A C': &'HMAC',
			&'H Box': &'H-Box',
			&'V Box': &'V-Box',
			&'H Flow': &'H-Flow',
			&'V Flow': &'V-Flow',
			&'H Scroll': &'H-Scroll',
			&'V Scroll': &'V-Scroll',
			&'H Separator': &'H-Separator',
			&'V Separator': &'V-Separator',
			&'H Slider': &'H-Slider',
			&'V Slider': &'V-Slider',
			&'H Split': &'H-Split',
			&'V Split': &'V-Split',
			&'O S': &'OS',
			&'H T T P': &'HTTP',
			&'I P': &'IP',
			&'M I D I': &'MIDI',
			&'J N I': &'JNI',
			&'J S O N': &'JSON',
			&'G I': &'GI',
			&'A P I': &'API',
			&'O R M': &'ORM',
			&'Open X R': &'OpenXR',
			&'X R': &'XR',
			&'P C K': &'PCK',
			&'U D P': &'UDP',
			&'Quad ': &'Quad-',
		}
		for key in replacement:
			ft_text.replace(key, replacement[key])
		filetype_label.text = ft_text
	
