extends Node2D

var fill: Polygon2D
var outline: Polygon2D

var velocity := Vector2.ZERO
var rotation_speed := 0.0
var gravity_strength := 1200.0
var lifetime := 2.5

func _ready():
	lifetime = 1.5
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(lifetime - 0.3)
	tween.tween_callback(queue_free)

func _process(delta):
	velocity.y += gravity_strength * delta
	position += velocity * delta
	rotation += rotation_speed * delta

func setup(points: PackedVector2Array, color: Color, start_pos: Vector2, start_rot: float, start_vel: Vector2, rot_speed: float):
	if not fill:
		fill = Polygon2D.new()
		add_child(fill)
	
	if not outline:																																																																					
		outline = Polygon2D.new()
		add_child(outline)

	fill.polygon = points
	fill.color = color
	
	outline.polygon = points
	outline.color = Color.BLACK
	outline.scale = Vector2(1.1, 1.1)
	outline.z_index = -1

	position = start_pos
	rotation = start_rot
	velocity = start_vel
	rotation_speed = rot_speed
