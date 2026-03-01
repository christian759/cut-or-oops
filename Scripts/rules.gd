extends Control

@onready var shape_scene = preload("res://Scenes/Shape.tscn")
@onready var shapes_container = $ShapesContainer
@onready var rule_label = $UI/RuleLabel
@onready var score_label = $UI/ScoreLabel
@onready var oops_overlay = $UI/OopsOverlay
@onready var oops_label = $UI/OopsOverlay/OopsLabel
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

var game_active = true

func _ready():
	randomize()
	_generate_new_rule()
	for i in 12:
		_spawn_shape()

func _spawn_shape():
	var s = shape_scene.instantiate()
	shapes_container.add_child(s)

func _generate_new_rule():
	current_rule_type = randi() % 2 as RuleType
	target_count = randi() % 3 + 3 # 3 to 5
	current_progress = 0
	
	if current_rule_type == RuleType.TYPE_ONLY:
		target_shape = randi() % 6
		rule_label.text = "CUT %d %s" % [target_count, _get_shape_name(target_shape)]
	else:
		target_color = randi() % 4
		rule_label.text = "CUT %d %s SHAPES" % [target_count, _get_color_name(target_color)]
	
	_update_score_ui()

func _get_shape_name(type: int) -> String:
	var names = ["TRIANGLES", "SQUARES", "TRAPEZIUMS", "RHOMBUSES", "PENTAGONS", "HEXAGONS"]
	return names[type]

func _get_color_name(color_type: int) -> String:
	var names = ["RED", "BLUE", "YELLOW", "GREEN"]
	return names[color_type]

func _process(delta):
	if cut_line.points.size() > 0:
		cut_line.modulate.a -= delta * 3.0
		if cut_line.modulate.a <= 0:
			cut_line.clear_points()

func _input(event):
	if not game_active: return
	
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			is_drawing = true
			last_mouse_pos = event.position
			cut_line.clear_points()
			cut_line.add_point(last_mouse_pos)
			cut_line.modulate.a = 1.0
		else:
			is_drawing = false
			
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_drawing:
			var current_pos = event.position
			cut_line.add_point(current_pos)
			cut_line.modulate.a = 1.0
			_check_cut(last_mouse_pos, current_pos)
			last_mouse_pos = current_pos

func _check_cut(start_pos: Vector2, end_pos: Vector2):
	for shape in shapes_container.get_children():
		if shape.is_cut: continue
		
		var closest_point = Geometry2D.get_closest_point_to_segment(shape.position, start_pos, end_pos)
		if closest_point.distance_to(shape.position) < shape.radius:
			shape.cut_shape()
			_spawn_shape()
			_evaluate_cut(shape)

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
		_update_score_ui()
		if current_progress >= target_count:
			_generate_new_rule()
	else:
		_trigger_oops()

func _update_score_ui():
	score_label.text = "SCORE: %d\nPROGRESS: %d/%d" % [score, current_progress, target_count]

func _trigger_oops():
	game_active = false
	oops_overlay.visible = true
	
	var tween = create_tween()
	oops_label.scale = Vector2.ZERO
	tween.tween_property(oops_label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Scenes/home.tscn")
