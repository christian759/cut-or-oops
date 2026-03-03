extends Node

enum GameMode {
	RULES,
	SURVIVAL,
	RUSH,
	NORMAL
}

var current_mode: GameMode = GameMode.RULES
