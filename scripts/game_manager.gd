extends Node

## Nodes
@onready var player: CharacterBody2D = %Player
@onready var coin_ui: TextureRect = $CanvasLayer/CoinUI/MarginContainer/TextureRect
@onready var heart_ui: AnimatedSprite2D = %HeartUI
@onready var event_flags: Array[Area2D] = [$ChaserEvent/EventFlag, $ChaserEvent/EventFlag2, $ChaserEvent/EventFlag3]

var chaser_scene: PackedScene = load("res://scenes/chars/the_chaser.tscn")
var chaser = null
var chaser_spawned: bool = false
@onready var start_marker: Marker2D = $WanderPositions/StartMarker

## GAME STATES
@onready var exit_door: StaticBody2D = $ExitDoor
@onready var levers: Array[Node] = [$Levers/LeverBlue, $Levers/LeverYellow, $Levers/LeverRed]
var light_states: Dictionary[String, bool] = {"blue": false, "yellow": false, "red": false}
var lever_states: Dictionary[String, bool] = {"blue": false, "yellow": false, "red": false}


## Settings and config
var ingame_settings_menu: PackedScene = load("res://scenes/ui_scenes/settings_menu_ingame.tscn")
var settings_scene

func _ready() -> void:
	levers[0].activate.connect(_on_blue_lever_activate)
	levers[1].activate.connect(_on_yellow_lever_activate)
	levers[2].activate.connect(_on_red_lever_activate)
	
	player.died.connect(_on_player_death)

func _process(delta: float) -> void:
	_coin_ui_handler()
	_check_game_state()
	_heart_ui_handler()


func _coin_ui_handler():
	if player.has_coin:
		coin_ui.visible = true
	else:
		coin_ui.visible = false


func _input(event: InputEvent) -> void:
	return
	if Input.is_action_just_pressed("open_settings"):
		settings_scene = ingame_settings_menu.instantiate()
		add_child(settings_scene)
		settings_scene.unpause.connect(_on_unpause)
		settings_scene.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true

func _check_game_state():
	for key in light_states:
		if light_states[key]:
			exit_door.light_states[key] = light_states[key]


## SIGNAL HANDLING
func _on_unpause():
	get_tree().paused = false

func _on_event_flag():
	if chaser_spawned:
		return
	
	chaser = chaser_scene.instantiate()
	add_child(chaser)
	chaser.position = start_marker.position


func _on_event_flag_flag_event() -> void:
	if chaser_spawned:
		return
	
	chaser = chaser_scene.instantiate()
	add_child(chaser)
	chaser.position = start_marker.position
	chaser.path_dest = player
	chaser_spawned = true

func _heart_ui_handler():
	if !chaser_spawned:
		return
	
	if player.position.distance_to(chaser.position) < 200.0:
		if heart_ui.animation == "beating_heart_chaser":
			return
		heart_ui.play("beating_heart_chaser")
	else:
		if heart_ui.animation == "beating_heart":
			return
		heart_ui.play("beating_heart")

func _on_blue_lever_activate():
	light_states["blue"] = true

func _on_yellow_lever_activate():
	light_states["yellow"] = true

func _on_red_lever_activate():
	light_states["red"] = true

func _on_player_death():
	get_tree().reload_current_scene()
