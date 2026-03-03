extends Control

@onready var loading_label: Label = $CenterContainer/VBoxContainer/Label2
var dots_count: int = 0
var animation_timer: float = 0.0
var dot_interval: float = 0.4

func _process(delta: float) -> void:
	animation_timer += delta
	if animation_timer >= dot_interval:
		animation_timer = 0.0
		dots_count = (dots_count + 1) % 4
		var dots = ""
		for i in range(dots_count):
			dots += "."
		loading_label.text = "Loading chaos" + dots

	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://Scenes/home.tscn")
