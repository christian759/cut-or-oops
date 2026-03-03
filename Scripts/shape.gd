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

func cut_shape(line_start: Vector2, line_end: Vector2):
	if is_cut: return
	is_cut = true
	
	var local_start = to_local(line_start)
	var local_end = to_local(line_end)
	
	var polys = _split_polygon(fill.polygon, local_start, local_end)
	
	if polys.size() >= 2:
		var cut_dir = (line_end - line_start).normalized()
		var force_dir = Vector2(-cut_dir.y, cut_dir.x)
		
		# Sort polys so we know which is "left" and "right" based on force_dir
		for i in range(polys.size()):
			var poly = polys[i]
			if poly.size() < 3: continue
			
			var center = Vector2.ZERO
			for p in poly: center += p
			center /= poly.size()
			
			var side = 1.0 if (center - Vector2.ZERO).dot(force_dir) > 0 else -1.0
			var frag_vel = velocity + force_dir * side * 200.0 + Vector2(0, -100)
			var frag_rot = deg_to_rad(rotation_speed) * 2.0 * side
			
			_spawn_fragment(poly, frag_vel, frag_rot)
	
	queue_free()

func _spawn_fragment(poly: PackedVector2Array, frag_vel: Vector2, frag_rot: float):
	var frag_script = load("res://Scripts/shape_fragment.gd")
	var frag = Node2D.new()
	frag.set_script(frag_script)
	get_parent().add_child(frag)
	frag.setup(poly, fill.color, global_position, global_rotation, frag_vel, frag_rot)

func _split_polygon(poly: PackedVector2Array, p1: Vector2, p2: Vector2) -> Array[PackedVector2Array]:
	var left_poly := PackedVector2Array()
	var right_poly := PackedVector2Array()
	
	var line_vec = p2 - p1
	var normal = Vector2(-line_vec.y, line_vec.x).normalized()
	
	for i in range(poly.size()):
		var a = poly[i]
		var b = poly[(i + 1) % poly.size()]
		
		var dist_a = (a - p1).dot(normal)
		var dist_b = (b - p1).dot(normal)
		
		if dist_a >= 0:
			left_poly.append(a)
		else:
			right_poly.append(a)
			
		if (dist_a > 0 and dist_b < 0) or (dist_a < 0 and dist_b > 0):
			var t = dist_a / (dist_a - dist_b)
			var intersect = a + (b - a) * t
			left_poly.append(intersect)
			right_poly.append(intersect)
			
	var result: Array[PackedVector2Array] = []
	if left_poly.size() >= 3: result.append(left_poly)
	if right_poly.size() >= 3: result.append(right_poly)
	return result
