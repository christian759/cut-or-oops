extends Control

@export var shape_scene: PackedScene
@export var shape_count := 12

@onready var shapes_layer := $Shapes

func _ready():
	randomize()
	_set_fullscreen()
	spawn_floating_shapes()

func _set_fullscreen():
	anchors_preset = Control.PRESET_FULL_RECT
	size = get_viewport_rect().size

func spawn_floating_shapes():
	var screen = get_viewport_rect().size
	for i in shape_count:
		var shape = shape_scene.instantiate()
		shapes_layer.add_child(shape)
		
		var start_pos = Vector2(randf_range(50, screen.x-50), randf_range(50, screen.y-50))
		var angle = randf() * TAU
		var vel = Vector2(cos(angle), sin(angle)) * randf_range(100, 200)
		var rot = randf_range(-50, 50)
		
		shape.setup(start_pos, vel, rot, false)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/ModeSelect.tscn")
