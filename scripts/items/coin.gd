extends RigidBody2D

enum COIN_STATES {EQUIPPED, FLYING, PICKABLE}
const ACTIONS := ["throw", "pick_up"] # Only to keep track of available actions

var particles: CPUParticles2D
var animated_sprite: AnimatedSprite2D

@export var _next_state: COIN_STATES
@export var _current_state: COIN_STATES

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	particles = $CPUParticles2D
	animated_sprite = $AnimatedSprite2D
	
	particles.emitting = false
	
	var _next_state = COIN_STATES.EQUIPPED
	var _current_state = _next_state
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _current_state != _next_state:
		_current_state = _next_state
	
	particle_process()

func _physics_process(delta: float) -> void:
	pass


func particle_process() -> void:
	if _current_state == COIN_STATES.PICKABLE:
		particles.emitting = true
	else:
		particles.emitting = false

# METHODS TO BE CALLED BY PLAYER ACTIONS
func throw() -> void:
	_next_state = COIN_STATES.FLYING
	print("COIN IS THROWN")

func pick_up() -> void:
	_next_state = COIN_STATES.EQUIPPED
