extends StaticBody2D

## Nodes
@onready var sparks: CPUParticles2D = $CPUParticles2D
@onready var audioplayer: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var lantern_light: PointLight2D = $PointLight2D
@onready var timer: Timer = $Timer

## States
var _current_active_state: bool = false
var _next_active_state: bool = false

## Other
var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if _current_active_state != _next_active_state:
		_current_active_state = _next_active_state
	
	tween = create_tween()
	tween.finished.connect(_on_tween_finished)
	timer.timeout.connect(_on_timer_timeout)
	lantern_light.texture_scale = 2.0
	
	if tween.is_running():
		print("TWEEN RUNNING")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## Signal call functions
func _on_coin_detect_area_area_entered(area: Area2D) -> void:
	if not area.is_in_group("coin"):
		return
	print("HIT LANTERN")
	sparks.emitting = true
	audioplayer.play()
	tween.tween_property(lantern_light,"texture_scale" ,3.0, 1.0)
	_next_active_state = !_current_active_state

func _on_tween_finished():
	tween.kill()
	timer.start(5.0)

func _on_timer_timeout():
	print("DIMMING LIGHT")
	tween.tween_property(lantern_light, "texture_scale", 0.2, 0.5)
	_next_active_state = !_current_active_state
