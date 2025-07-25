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
	timer.timeout.connect(_on_timer_timeout)


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
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.finished.connect(_on_tween_finished)
	tween.tween_property(lantern_light, "texture_scale", 3.0, 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel()
	tween.tween_property(lantern_light, "energy", 1.5, 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	_next_active_state = !_current_active_state

func _on_tween_finished():
	tween.kill()
	timer.start(5.0)

func _on_timer_timeout():
	print("DIMMING LIGHT")
	
	tween = create_tween()
	tween.tween_property(lantern_light, "texture_scale", 0.2, 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel()
	tween.tween_property(lantern_light, "energy", 0.2, 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	_next_active_state = !_current_active_state
