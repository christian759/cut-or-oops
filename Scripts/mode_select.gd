extends Control

func _ready():
	if has_node("VBoxContainer/ButtonContainer/RulesButton"):
		get_node("VBoxContainer/ButtonContainer/RulesButton").hide()

func _on_survival_button_pressed() -> void:
	Global.current_mode = Global.GameMode.SURVIVAL
	_start_game()

func _on_rush_button_pressed() -> void:
	Global.current_mode = Global.GameMode.RUSH
	_start_game()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/home.tscn")

func _start_game():
	get_tree().change_scene_to_file("res://Scenes/Rules.tscn")
