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
	for i in shape_count:
		var shape = shape_scene.instantiate()
		shapes_layer.add_child(shape)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Rules.tscn")
