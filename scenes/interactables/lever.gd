class_name Lever
extends StaticBody2D

## Signals
signal activate

## Nodes
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

## States
var _current_active_state: bool = false
var _next_active_state: bool = false

## Vars
var id: int

func _process(delta: float) -> void:
	if _current_active_state != _next_active_state:
		_current_active_state = _next_active_state
		_animation_audio_handler()

func _animation_audio_handler():
	match _current_active_state:
		true:
			activate.emit()
			audio_player.play()
			animation.play("activate")
		false:
			audio_player.play()
			animation.play("de_activate")

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not area.is_in_group("coin"):
		return
	
	_next_active_state = !_current_active_state
