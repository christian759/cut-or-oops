extends Control

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/home.tscn")

func _on_volume_slider_value_changed(value: float) -> void:
	# Placeholder for volume logic
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
