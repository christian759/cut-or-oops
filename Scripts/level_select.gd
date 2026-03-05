extends Control

@onready var grid = $VBoxContainer/ScrollContainer/GridContainer
@onready var back_button = $VBoxContainer/BackButton

func _ready():
	_setup_ui()
	_populate_levels()

func _setup_ui():
	# Matching ModeSelect style
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color.WHITE
	style_normal.border_width_left = 6
	style_normal.border_width_top = 6
	style_normal.border_width_right = 6
	style_normal.border_width_bottom = 14
	style_normal.border_color = Color.BLACK
	style_normal.corner_radius_top_left = 16
	style_normal.corner_radius_top_right = 16
	style_normal.corner_radius_bottom_right = 16
	style_normal.corner_radius_bottom_left = 16
	style_normal.content_margin_left = 20
	style_normal.content_margin_top = 20
	style_normal.content_margin_right = 20
	style_normal.content_margin_bottom = 20

	var style_locked = style_normal.duplicate()
	style_locked.bg_color = Color(0.4, 0.4, 0.4)
	style_locked.border_color = Color(0.2, 0.2, 0.2)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.8, 0.8, 0.8)
	style_pressed.border_width_top = 10
	style_pressed.border_width_bottom = 6
	
	# Apply to back button
	back_button.add_theme_stylebox_override("normal", style_normal)
	back_button.add_theme_stylebox_override("pressed", style_pressed)
	back_button.add_theme_stylebox_override("hover", style_normal)

func _populate_levels():
	var font = preload("res://Assets/monogram/ttf/monogram.ttf")
	
	# Clear existing if any
	for child in grid.get_children():
		child.queue_free()
		
	# Determine columns based on screen width
	var screen_width = get_viewport_rect().size.x
	grid.columns = floor((screen_width - 80) / 160) # roughly 120 + 40 spacing
	
	for i in range(1, 201):
		var btn = Button.new()
		btn.text = str(i)
		btn.custom_minimum_size = Vector2(140, 140)
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 50)
		btn.add_theme_color_override("font_color", Color.BLACK)
		
		# Premium styling helper usage
		_style_level_button(btn, i <= Global.unlocked_levels)
		
		if i <= Global.unlocked_levels:
			btn.pressed.connect(_on_level_selected.bind(i))
		else:
			btn.disabled = true
			btn.modulate.a = 0.6
			
		grid.add_child(btn)

func _style_level_button(btn: Button, is_unlocked: bool):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color.WHITE if is_unlocked else Color(0.7, 0.7, 0.7)
	style_normal.border_width_left = 6
	style_normal.border_width_top = 6
	style_normal.border_width_right = 6
	style_normal.border_width_bottom = 12
	style_normal.border_color = Color.BLACK
	style_normal.corner_radius_top_left = 12
	style_normal.corner_radius_top_right = 12
	style_normal.corner_radius_bottom_right = 12
	style_normal.corner_radius_bottom_left = 12
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.9, 0.9, 0.9)
	style_pressed.border_width_top = 10
	style_pressed.border_width_bottom = 6
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("hover", style_normal)
	btn.add_theme_stylebox_override("disabled", style_normal)

func _on_level_selected(level: int):
	Global.selected_level = level
	Global.current_mode = Global.GameMode.NORMAL
	get_tree().change_scene_to_file("res://Scenes/Rules.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/ModeSelect.tscn")
