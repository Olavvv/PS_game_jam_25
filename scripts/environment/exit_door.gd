extends StaticBody2D

## Nodes
@onready var exit_zone: Area2D = $ExitZone
@onready var door_lights: Dictionary[String, Sprite2D] = {"blue": $DoorLights/DoorLightBlue, "yellow": $DoorLights/DoorLightYellow, "red": $DoorLights/DoorLightRed}
var light_states: Dictionary[String, bool] = {"blue": false, "yellow": false, "red": false}
var is_complete: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for door_light in door_lights.values():
		door_light.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	count_levers()
	
	if is_complete:
		visible = false
	
	if light_states["blue"]:
		door_lights["blue"].visible = true
	
	if light_states["yellow"]:
		door_lights["yellow"].visible = true
	
	if light_states["red"]:
		door_lights["red"].visible = true

func count_levers():
	var num_levers_hit: int = 0
	for light_state in light_states.values():
		if light_state: num_levers_hit += 1
	if num_levers_hit == 3:
		is_complete = true

func _on_exit_zone_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	if is_complete:
		get_tree().change_scene_to_file("res://scenes/cutscenes/end_cutscene.tscn")
