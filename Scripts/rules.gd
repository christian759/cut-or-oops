extends Control

@onready var shape_scene = preload("res://Scenes/Shape.tscn")
@onready var shapes_container = $ShapesContainer
@onready var rule_label = $UI/RuleLabel
@onready var score_label = $UI/ScoreLabel
@onready var oops_overlay = $UI/OopsOverlay
@onready var oops_label = $UI/OopsOverlay/OopsLabel
var rule_popup: ColorRect
var popup_label: Label
@onready var cut_line = $CutLine

var is_drawing = false
var last_mouse_pos = Vector2.ZERO
var score = 0

enum RuleType { TYPE_ONLY, COLOR_ONLY }
var current_rule_type: RuleType
var target_shape: int
var target_color: int
var target_count = 0
var current_progress = 0

var game_active = false
var spawn_timer := 0.0
var spawn_interval := 1.5

var rush_time_left := 0.0
var is_rush_mode := false
var is_survival_mode := false
var is_normal_mode := false
var survival_round := 0
var normal_level := 1
var time_label: Label
var slash_audio: AudioStreamPlayer

func _ready():
	randomize()
	_initialize_mode()
	_ensure_popup_ui()
	_generate_new_rule()
	
	rule_label.show() # Ensure it's visible
	# Style rule_label further
	rule_label.add_theme_font_size_override("font_size", 50)
	rule_label.add_theme_color_override("font_outline_color", Color.BLACK)
	rule_label.add_theme_constant_override("outline_size", 12)
	
	# Audio setup
	slash_audio = AudioStreamPlayer.new()
	add_child(slash_audio)
	# Users will need to set slash_audio.stream to an actual sound file
	
	# Knife Slash Visuals
	cut_line.width = 20.0
	var curve = Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.5, 1))
	curve.add_point(Vector2(1, 0))
	cut_line.width_curve = curve
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 0))
	gradient.add_point(0.2, Color(1, 1, 1, 1))
	gradient.add_point(0.8, Color(1, 1, 1, 1))
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	cut_line.gradient = gradient
	
	_show_rule_popup()

func _initialize_mode():
	if Global.current_mode == Global.GameMode.RUSH:
		is_rush_mode = true
		rush_time_left = 60.0
	elif Global.current_mode == Global.GameMode.SURVIVAL:
		is_survival_mode = true
		survival_round = 0
	elif Global.current_mode == Global.GameMode.NORMAL:
		is_normal_mode = true
		normal_level = Global.selected_level
	else:
		is_rush_mode = false
		is_survival_mode = false
		is_normal_mode = false

func _ensure_popup_ui():
	if not has_node("UI/RulePopup"):
		var canvas = get_node("UI")
		
		# Enhanced Dark/Glass Backdrop
		rule_popup = ColorRect.new()
		rule_popup.name = "RulePopup"
		rule_popup.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		rule_popup.size = Vector2(700, 500)
		rule_popup.position -= rule_popup.size / 2.0
		rule_popup.color = Color(0, 0, 0, 0.85) # Dark premium background
		rule_popup.visible = false
		canvas.add_child(rule_popup)
		
		# Vibrant Border
		var border = ReferenceRect.new()
		border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		border.border_color = Color("F4A261") # Match yellow/orange theme
		border.border_width = 12
		border.editor_only = false
		rule_popup.add_child(border)
		
		popup_label = Label.new()
		popup_label.name = "PopupLabel"
		popup_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		popup_label.add_theme_color_override("font_color", Color.WHITE)
		popup_label.add_theme_font_size_override("font_size", 45)
		popup_label.add_theme_font_override("font", preload("res://Assets/monogram/ttf/monogram.ttf"))
		popup_label.text = "RULES"
		rule_popup.add_child(popup_label)
		
	if not has_node("UI/TimeLabel"):
		time_label = Label.new()
		time_label.name = "TimeLabel"
		time_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		time_label.offset_left = -300
		time_label.offset_top = 40
		time_label.offset_right = -40
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		time_label.add_theme_font_size_override("font_size", 60)
		time_label.add_theme_color_override("font_color", Color("E63946"))
		time_label.add_theme_color_override("font_outline_color", Color.BLACK)
		time_label.add_theme_constant_override("outline_size", 12)
		time_label.add_theme_font_override("font", preload("res://Assets/monogram/ttf/monogram.ttf"))
		$UI.add_child(time_label)
		time_label.hide()
	else:
		time_label = $UI/TimeLabel

func _show_rule_popup():
	game_active = false
	rule_popup.visible = true
	
	var mode_name = ""
	match Global.current_mode:
		Global.GameMode.RULES: mode_name = "RULES CHALLENGE"
		Global.GameMode.SURVIVAL: mode_name = "SURVIVAL MODE"
		Global.GameMode.RUSH: mode_name = "RUSH ATTACK"
		Global.GameMode.NORMAL: mode_name = "NORMAL MODE"
	
	popup_label.text = "[ %s ]\n\n%s\n\n[ TAP TO START ]" % [mode_name, rule_label.text]
	
	# Entrance Animation
	rule_popup.scale = Vector2.ZERO
	rule_popup.pivot_offset = rule_popup.size / 2.0
	var tween = create_tween()
	tween.tween_property(rule_popup, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_gameplay():
	rule_popup.visible = false
	game_active = true
	
	if is_rush_mode:
		time_label.show()
	else:
		time_label.hide()

func _generate_new_rule():
	current_rule_type = randi() % 2 as RuleType
	current_progress = 0
	
	if is_rush_mode:
		target_count = randi() % 4 + 4 + int(score / 500) # Increases with score
	elif is_survival_mode:
		survival_round += 1
		target_count = 3 + int(survival_round / 1.5) # Faster scaling
		_show_round_announcement("ROUND %d" % survival_round)
	elif is_normal_mode:
		target_count = 3 + int(normal_level / 2.0) # Increases every 2 levels
		if score > 0 and current_progress >= target_count: # This shouldn't happen here but for safety
			pass 
	else:
		target_count = randi() % 3 + 3
	
	if current_rule_type == RuleType.TYPE_ONLY:
		target_shape = randi() % 6
		rule_label.text = "CUT %d %s" % [target_count, _get_shape_name(target_shape)]
	else:
		target_color = randi() % 4
		rule_label.text = "CUT %d %s SHAPES" % [target_count, _get_color_name(target_color)]
	
	_update_score_ui()

func _show_round_announcement(title_text: String):
	popup_label.text = "%s\n\nGET READY!" % title_text
	rule_popup.visible = true
	rule_popup.modulate.a = 1.0
	rule_popup.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.tween_property(rule_popup, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.5)
	tween.tween_property(rule_popup, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): 
		rule_popup.visible = false
		rule_popup.modulate.a = 1.0
		# Update rule after announcement
		popup_label.text = "[ SURVIVAL MODE ]\n\n%s\n\n[ TAP TO START ]" % rule_label.text
	)

func _get_difficulty_multiplier() -> float:
	var multiplier = 1.0
	if is_survival_mode:
		multiplier = 1.0 + (survival_round - 1) * 0.2 # 20% faster per round
	elif is_normal_mode:
		multiplier = 1.0 + (normal_level - 1) * 0.1 # 10% faster per level
	elif is_rush_mode:
		multiplier = 1.0 + (score / 1000.0) * 0.5 # 50% faster per 1000 points
	return multiplier

func _get_shape_name(type: int) -> String:
	var names = ["TRIANGLES", "SQUARES", "TRAPEZIUMS", "RHOMBUSES", "PENTAGONS", "HEXAGONS"]
	return names[type]

func _get_color_name(color_type: int) -> String:
	var names = ["RED", "BLUE", "YELLOW", "GREEN"]
	return names[color_type]

func _process(delta):
	if game_active:
		if is_rush_mode:
			rush_time_left -= delta
			time_label.text = "TIME: %0.1f" % max(0, rush_time_left)
			
			# Low time pulsing
			if rush_time_left < 10.0:
				time_label.modulate = Color.RED if int(rush_time_left * 4) % 2 == 0 else Color.WHITE
				time_label.scale = Vector2(1.2, 1.2) if int(rush_time_left * 4) % 2 == 0 else Vector2.ONE
				time_label.pivot_offset = time_label.size / 2.0
			else:
				time_label.modulate = Color.WHITE
				time_label.scale = Vector2.ONE

			if rush_time_left <= 0:
				rush_time_left = 0
				_trigger_game_over("TIME UP!")
				return

		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			_spawn_shape()

	if cut_line.points.size() > 0:
		cut_line.modulate.a -= delta * 8.0 # Very fast fade for knife effect
		if cut_line.modulate.a <= 0:
			cut_line.clear_points()
		elif cut_line.points.size() > 10:
			# Keep it short like a blade
			cut_line.remove_point(0)

func _input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			if rule_popup and rule_popup.visible:
				_start_gameplay()
				get_viewport().set_input_as_handled()
				return
			
			if oops_overlay and oops_overlay.visible:
				if not is_normal_mode:
					get_tree().change_scene_to_file("res://Scenes/home.tscn")
				get_viewport().set_input_as_handled()
				return
			
			if not game_active: return
				
			is_drawing = true
			last_mouse_pos = event.position
			cut_line.clear_points()
			cut_line.add_point(last_mouse_pos)
			cut_line.modulate.a = 1.0
		else:
			is_drawing = false
			
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if not game_active: return
		if is_drawing:
			var current_pos = event.position
			# Only add point if moved enough to avoid jagged lines
			if current_pos.distance_to(last_mouse_pos) > 5.0:
				cut_line.add_point(current_pos)
				cut_line.modulate.a = 1.0
				_check_cut(last_mouse_pos, current_pos)
				last_mouse_pos = current_pos

func _spawn_shape():
	var s = shape_scene.instantiate()
	shapes_container.add_child(s)
	
	var screen = get_viewport_rect().size
	var spawn_type = randf()
	var diff = _get_difficulty_multiplier()
	
	if spawn_type < 0.7: # 70% Toss from bottom
		var start_x = randf_range(100, screen.x - 100)
		var start_y = screen.y + 100
		
		var angle = randf_range(-PI/4, PI/4)
		if start_x > screen.x / 2:
			angle -= PI/10
		else:
			angle += PI/10
			
		var force = randf_range(700, 1000) * diff
		var vel = Vector2(0, -1).rotated(angle) * force
		var rot = randf_range(-200, 200) * diff
		s.setup(Vector2(start_x, start_y), vel, rot, true)
	else: # 30% Spawn on screen with bounce
		var start_pos = Vector2(
			randf_range(100, screen.x - 100),
			randf_range(100, screen.y - 100)
		)
		var angle = randf() * TAU
		var vel = Vector2(cos(angle), sin(angle)) * randf_range(100, 200) * diff
		var rot = randf_range(-100, 100) * diff
		s.setup(start_pos, vel, rot, false)
	
	spawn_interval = randf_range(0.8, 2.0) / diff

func _check_cut(start_pos: Vector2, end_pos: Vector2):
	for shape in shapes_container.get_children():
		if not shape is ShapeObject or shape.is_cut: continue
		
		# More robust check: check endpoints and midpoints to ensure we don't skip over fast shapes
		var mid_pos = (start_pos + end_pos) / 2.0
		if shape.is_point_inside(start_pos) or shape.is_point_inside(end_pos) or shape.is_point_inside(mid_pos):
			shape.cut_shape(start_pos, end_pos)
			_play_slash_sound()
			_evaluate_cut(shape)

func _play_slash_sound():
	if slash_audio.stream:
		slash_audio.play()

func _evaluate_cut(shape):
	var is_correct = false
	
	if current_rule_type == RuleType.TYPE_ONLY:
		if shape.shape_type == target_shape:
			is_correct = true
	elif current_rule_type == RuleType.COLOR_ONLY:
		if shape.shape_color == target_color:
			is_correct = true
			
	if is_correct:
		current_progress += 1
		score += 10
		if is_rush_mode:
			rush_time_left += 2.0 # Correct cut bonus
		
		_update_score_ui()
		if current_progress >= target_count:
			if is_rush_mode:
				rush_time_left += 10.0 # Rule completion bonus
			elif is_normal_mode:
				if normal_level == Global.unlocked_levels and normal_level < 200:
					Global.unlocked_levels += 1
					Global.save_data()
				_trigger_win("LEVEL %d COMPLETE!" % normal_level)
				return # Stop gameplay after level completion
			_generate_new_rule()
	else:
		if is_rush_mode:
			# Penalty instead of instant game over
			rush_time_left -= 5.0
			score = max(0, score - 5)
			_update_score_ui()
			_shake_screen() # Visual feedback
		else:
			_trigger_game_over("OOPS!")

func _shake_screen():
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(10, 10), 0.05)
	tween.tween_property(self, "position", Vector2(-10, -10), 0.05)
	tween.tween_property(self, "position", Vector2(0, 0), 0.05)

func _update_score_ui():
	# Premium score styling
	score_label.text = "SCORE: %d\nPROGRESS: %d/%d" % [score, current_progress, target_count]
	score_label.add_theme_font_size_override("font_size", 55)
	score_label.add_theme_color_override("font_color", Color("F4A261")) # Warm gold/orange
	score_label.add_theme_color_override("font_outline_color", Color.BLACK)
	score_label.add_theme_constant_override("outline_size", 10)
	
	# Slight punch animation on update
	var tween = create_tween()
	score_label.scale = Vector2(1.1, 1.1)
	score_label.pivot_offset = score_label.size / 2.0
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _trigger_game_over(message: String):
	game_active = false
	oops_overlay.visible = true
	oops_overlay.color = Color(0, 0, 0, 0.8) # Darker backdrop
	oops_label.text = message
	oops_label.add_theme_color_override("font_color", Color("E63946")) # Reddish
	oops_label.add_theme_font_size_override("font_size", 120)
	
	var tween = create_tween()
	oops_label.scale = Vector2.ZERO
	oops_label.pivot_offset = oops_label.size / 2.0
	tween.tween_property(oops_label, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	if is_normal_mode:
		_add_overlay_buttons(false)
	else:
		# Original Survival/Rush logic: Tap anywhere to go home
		var tap_label = Label.new()
		tap_label.text = "TAP TO CONTINUE"
		tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tap_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		tap_label.offset_top = -200
		tap_label.add_theme_font_size_override("font_size", 40)
		oops_overlay.add_child(tap_label)
		
		get_tree().create_timer(4.0).timeout.connect(func(): if oops_overlay.visible: get_tree().change_scene_to_file("res://Scenes/home.tscn"))

func _trigger_win(message: String):
	game_active = false
	oops_overlay.visible = true
	oops_overlay.color = Color(0, 0.4, 0.2, 0.8) # Deep green premium win color
	oops_label.text = message
	oops_label.add_theme_color_override("font_color", Color("2A9D8F")) # Greenish
	oops_label.add_theme_font_size_override("font_size", 120)
	
	var tween = create_tween()
	oops_label.scale = Vector2.ZERO
	oops_label.pivot_offset = oops_label.size / 2.0
	tween.tween_property(oops_label, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	_add_overlay_buttons(true)

func _add_overlay_buttons(is_win: bool):
	# Clear existing tap labels if any
	for child in oops_overlay.get_children():
		if child is Label and child != oops_label:
			child.queue_free()
	
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	button_container.offset_top = -200
	button_container.offset_left = -400
	button_container.offset_right = 400
	button_container.theme_override_constants/separation = 40
	oops_overlay.add_child(button_container)
	
	if is_win:
		var next_btn = Button.new()
		next_btn.text = "NEXT LEVEL"
		next_btn.add_theme_font_size_override("font_size", 45)
		next_btn.pressed.connect(func(): 
			Global.selected_level = min(200, normal_level + 1)
			get_tree().reload_current_scene()
		)
		if normal_level >= 200: next_btn.disabled = true
		button_container.add_child(next_btn)
	else:
		var retry_btn = Button.new()
		retry_btn.text = "RETRY"
		retry_btn.add_theme_font_size_override("font_size", 45)
		retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
		button_container.add_child(retry_btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "LEVEL SELECT"
	menu_btn.add_theme_font_size_override("font_size", 45)
	menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/LevelSelect.tscn"))
	button_container.add_child(menu_btn)
