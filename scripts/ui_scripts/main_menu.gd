extends Control

@onready var start_button: Button = $BoxContainer/CenterContainer/VBoxContainer/MarginContainer/Start
@onready var settings_button: Button = $BoxContainer/CenterContainer/VBoxContainer/MarginContainer2/Settings
@onready var exit_button: Button = $BoxContainer/CenterContainer/VBoxContainer/MarginContainer3/Exit

var main_game := "res://scenes/game.tscn"
var settings_menu := "res://scenes/ui_scenes/settings_menu.tscn"

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(main_game)


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(settings_menu)


func _on_exit_pressed() -> void:
	get_tree().quit()
