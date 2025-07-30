extends Area2D

enum COIN_STATES {FLYING, PICKABLE}
const ACTIONS := ["throw", "pick_up"] # Only to keep track of available actions

@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_sound_player: AudioStreamPlayer2D = $HitSound

var destination: Vector2
var duration: float = 0.3
var tween: Tween

@export var _next_state: COIN_STATES
@export var _current_state: COIN_STATES

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_shape.disabled = true
	particles.emitting = false
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_tween_finish)
	
	_next_state = COIN_STATES.FLYING
	_current_state = _next_state


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _current_state != _next_state:
		_current_state = _next_state
	
	_state_property_handler()


func _state_property_handler():
	match _current_state:
		COIN_STATES.FLYING:
			collision_shape.disabled = false
			particles.emitting = false
		
		COIN_STATES.PICKABLE:
			particles.emitting = true

func _on_tween_finish():
	tween.kill()
	_next_state = COIN_STATES.PICKABLE

# METHODS TO BE CALLED BY PLAYER ACTIONS
func throw(coin_dest: Vector2) -> void:
	tween.tween_property(self, "position", coin_dest, duration)

func pick_up() -> bool:
	if _current_state == COIN_STATES.PICKABLE:
		queue_free()
		return true
	return false


func _on_body_entered(body: Node2D) -> void:
	if tween and tween.is_valid():
		tween.kill()
	
	if _current_state == COIN_STATES.FLYING:
		hit_sound_player.play()
	
	_next_state = COIN_STATES.PICKABLE
