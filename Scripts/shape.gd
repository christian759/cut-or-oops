extends Area2D

class_name ShapeObject

enum ShapeType { TRIANGLE, SQUARE, TRAPEZIUM, RHOMBUS, PENTAGON, HEXAGON }
enum ShapeColorName { RED, BLUE, YELLOW, GREEN }

const COLORS = {
	ShapeColorName.RED: Color("E63946"),
	ShapeColorName.BLUE: Color("457B9D"),
	ShapeColorName.YELLOW: Color("F4A261"),
	ShapeColorName.GREEN: Color("2A9D8F")
}

@export var move_speed := 120.0
@export var rotation_speed := 30.0
@export var radius := 60.0

@onready var outline: Polygon2D = $Outline
@onready var fill: Polygon2D = $Fill
@onready var collision_poly: CollisionPolygon2D = $CollisionPolygon2D

var velocity := Vector2.ZERO
var shape_type: ShapeType
var shape_color: ShapeColorName
var is_cut := false

func _ready():
	_set_random_shape()
	_set_random_movement()
	_set_spawn_position()

func _set_spawn_position():
	var screen := get_viewport_rect().size
	position = Vector2(
		randf_range(radius, screen.x - radius),
		randf_range(radius, screen.y - radius)
	)

func _set_random_shape():
	var points: PackedVector2Array
	
	shape_type = randi() % ShapeType.size() as ShapeType
	shape_color = randi() % ShapeColorName.size() as ShapeColorName

	match shape_type:
		ShapeType.TRIANGLE:
			points = _regular_polygon(3)
		ShapeType.SQUARE:
			points = [Vector2(-radius,-radius), Vector2(radius,-radius), Vector2(radius,radius), Vector2(-radius,radius)]
		ShapeType.TRAPEZIUM:
			points = [Vector2(-radius,radius), Vector2(radius,radius), Vector2(radius*0.7,-radius), Vector2(-radius*0.7,-radius)]
		ShapeType.RHOMBUS:
			points = [Vector2(0,-radius), Vector2(radius,0), Vector2(0,radius), Vector2(-radius,0)]
		ShapeType.PENTAGON: 
			points = _regular_polygon(5)
		ShapeType.HEXAGON:
			points = _regular_polygon(6)

	fill.polygon = points
	outline.polygon = points
	collision_poly.polygon = points

	outline.color = Color.BLACK
	outline.scale = Vector2(1.15, 1.15)

	fill.color = COLORS[shape_color]

func _regular_polygon(sides: int) -> PackedVector2Array:
	var arr := PackedVector2Array()
	var offset = -PI/2.0
	for i in sides:
		var a: float = offset + TAU * float(i) / float(sides)
		arr.append(Vector2(cos(a), sin(a)) * radius)
	return arr

func _set_random_movement():
	var angle := randf() * TAU
	velocity = Vector2(cos(angle), sin(angle)) * move_speed

func _process(delta):
	position += velocity * delta
	rotation += deg_to_rad(rotation_speed) * delta

	var screen := get_viewport_rect().size

	if position.x <= radius:
		position.x = radius
		velocity.x *= -1
	elif position.x >= screen.x - radius:
		position.x = screen.x - radius
		velocity.x *= -1

	if position.y <= radius:
		position.y = radius
		velocity.y *= -1
	elif position.y >= screen.y - radius:
		position.y = screen.y - radius
		velocity.y *= -1

func cut_shape():
	if is_cut: return
	is_cut = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
