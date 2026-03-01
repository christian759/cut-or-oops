extends Area2D

@export var move_speed := 120.0
@export var rotation_speed := 30.0
@export var radius := 50.0

@onready var outline: Polygon2D = $Outline
@onready var fill: Polygon2D = $Fill
@onready var collision_poly: CollisionPolygon2D = $CollisionPolygon2D

var velocity := Vector2.ZERO

func _ready():
	randomize()
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

	match randi() % 6:
		0: points = [Vector2(0,-radius), Vector2(radius,radius), Vector2(-radius,radius)]
		1: points = [Vector2(-radius,-radius), Vector2(radius,-radius), Vector2(radius,radius), Vector2(-radius,radius)]
		2: points = [Vector2(-radius,radius), Vector2(radius,radius), Vector2(radius*0.7,-radius), Vector2(-radius*0.7,-radius)]
		3: points = [Vector2(0,-radius), Vector2(radius,0), Vector2(0,radius), Vector2(-radius,0)]
		4: points = _regular_polygon(5)
		5: points = _regular_polygon(6)

	fill.polygon = points
	outline.polygon = points
	collision_poly.polygon = points

	outline.color = Color.BLACK
	outline.scale = Vector2(1.12, 1.12)

	fill.color = Color.from_hsv(randf(), 0.7, 0.95)

func _regular_polygon(sides: int) -> PackedVector2Array:
	var arr := PackedVector2Array()
	for i in sides:
		var a := TAU * i / sides
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
