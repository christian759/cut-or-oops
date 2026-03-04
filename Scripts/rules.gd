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
var time_label: Label
var slash_audio: AudioStreamPlayer

func _ready():
	randomize()
	_ensure_popup_ui()
	_generate_new_rule()
	rule_label.hide()
	
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

func _ensure_popup_ui():
	if not has_node("UI/RulePopup"):
		var canvas = get_node("UI")
		
		rule_popup = ColorRect.new()
		rule_popup.name = "RulePopup"
		rule_popup.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		rule_popup.size = Vector2(600, 400)
		rule_popup.position -= rule_popup.size / 2.0
		rule_popup.color = Color(1, 1, 1, 0.9)
		rule_popup.visible = false
		canvas.add_child(rule_popup)
		
		# Add outline to popup
		var outline = ReferenceRect.new()
		outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		outline.border_color = Color.BLACK
		outline.border_width = 8
		outline.editor_only = false
		rule_popup.add_child(outline)
		
		popup_label = Label.new()
		popup_label.name = "PopupLabel"
		popup_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		popup_label.add_theme_color_override("font_color", Color.BLACK)
		popup_label.add_theme_font_size_override("font_size", 40)
		popup_label.text = "RULES"
		rule_popup.add_child(popup_label)
		
	if not has_node("UI/TimeLabel"):
		time_label = Label.new()
		time_label.name = "TimeLabel"
		time_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		time_label.position += Vector2(-20, 20) # Small offset
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		time_label.add_theme_font_size_override("font_size", 40)
		time_label.add_theme_color_override("font_outline_color", Color.BLACK)
		time_label.add_theme_constant_override("outline_size", 8)
		$UI.add_child(time_label)
		time_label.hide()
	else:
		time_label = $UI/TimeLabel

func _show_rule_popup():
	game_active = false
	rule_popup.visible = true
	
	var mode_name = ""
	match Global.current_mode:
		Global.GameMode.RULES: mode_name = "RULES MODE"
		Global.GameMode.SURVIVAL: mode_name = "SURVIVAL"
		Global.GameMode.RUSH: mode_name = "RUSH"
	
	popup_label.text = "[%s]\n\n%s\n\nTAP TO START" % [mode_name, rule_label.text]
	
	# Small animation
	rule_popup.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(rule_popup, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_gameplay():
	rule_popup.visible = false
	game_active = true
	
	if Global.current_mode == Global.GameMode.RUSH:
		is_rush_mode = true
		rush_time_left = 60.0
		time_label.show()
	elif Global.current_mode == Global.GameMode.SURVIVAL:
		is_survival_mode = true
		survival_round = 0
		time_label.hide()
	elif Global.current_mode == Global.GameMode.NORMAL:
		is_normal_mode = true
		time_label.hide()
	else:
		is_rush_mode = false
		is_survival_mode = false
		is_normal_mode = false
		time_label.hide()

func _generate_new_rule():
	current_rule_type = randi() % 2 as RuleType
	current_progress = 0
	
	if is_rush_mode:
		target_count = randi() % 4 + 4 # 4 to 7
	elif is_survival_mode:
		survival_round += 1
		target_count = 3 + int(float(survival_round) / 2.0) # Slowly increases
		_show_round_announcement()
	else:
		target_count = randi() % 3 + 3 # 3 to 5
		if is_normal_mode and score >= 100: # Example win condition for normal
			_trigger_win("LEVEL COMPLETE!")
			return
	
	if current_rule_type == RuleType.TYPE_ONLY:
		target_shape = randi() % 6
		rule_label.text = "CUT %d %s" % [target_count, _get_shape_name(target_shape)]
	else:
		target_color = randi() % 4
		rule_label.text = "CUT %d %s SHAPES" % [target_count, _get_color_name(target_color)]
	
	_update_score_ui()

func _show_round_announcement():
	# Repurpose popup_label for a quick "ROUND X" flash
	var original_text = popup_label.text
	popup_label.text = "ROUND %d" % survival_round
	rule_popup.visible = true
	rule_popup.modulate.a = 1.0
	rule_popup.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.tween_property(rule_popup, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.0)
	tween.tween_property(rule_popup, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): 
		rule_popup.visible = false
		rule_popup.modulate.a = 1.0
		popup_label.text = original_text
	)

func _get_difficulty_multiplier() -> float:
	if is_survival_mode:
		return 1.0 + (survival_round - 1) * 0.15 # 15% faster per round
	return 1.0

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
			time_label.text = "TIME: %0.1f" % rush_time_left
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
			_generate_new_rule()
	else:
		if is_rush_mode or is_normal_mode:
			# Penalty instead of instant game over
			if is_rush_mode:
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
	score_label.text = "SCORE: %d\nPROGRESS: %d/%d" % [score, current_progress, target_count]

func _trigger_game_over(message: String):
	game_active = false
	oops_overlay.visible = true
	oops_label.text = message
	
	var tween = create_tween()
	oops_label.scale = Vector2.ZERO
	tween.tween_property(oops_label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	await Global.show_ad_if_needed(self)
	get_tree().change_scene_to_file("res://Scenes/home.tscn")

func _trigger_win(message: String):
	game_active = false
	oops_overlay.visible = true
	oops_overlay.color = Color(0, 0.8, 0, 0.5) # Greenish for win
	oops_label.text = message
	
	var tween = create_tween()
	oops_label.scale = Vector2.ZERO
	tween.tween_property(oops_label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	await Global.show_ad_if_needed(self)
	get_tree().change_scene_to_file("res://Scenes/home.tscn")
