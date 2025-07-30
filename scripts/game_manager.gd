extends Node

## Nodes
@onready var player: CharacterBody2D = %Player
@onready var coin_ui: TextureRect = $CanvasLayer/CoinUI/MarginContainer/TextureRect
@onready var heart_ui: AnimatedSprite2D = %HeartUI

## Settings and config
var ingame_settings_menu: PackedScene = load("res://scenes/ui_scenes/settings_menu_ingame.tscn")
var settings_scene

func _process(delta: float) -> void:
	_coin_ui_handler()


func _coin_ui_handler():
	if player.has_coin:
		coin_ui.visible = true
	else:
		coin_ui.visible = false


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("open_settings"):
		settings_scene = ingame_settings_menu.instantiate()
		add_child(settings_scene)
		settings_scene.unpause.connect(_on_unpause)
		settings_scene.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true


## SIGNAL HANDLING
func _on_unpause():
	get_tree().paused = false
