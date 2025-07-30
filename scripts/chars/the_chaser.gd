extends CharacterBody2D

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var walk_sound_player: AudioStreamPlayer2D = $WalkSoundPlayer
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var idle_timer: Timer = $IdleTimer
@onready var stun_timer: Timer = $StunTimer
@onready var enter_audio: AudioStreamPlayer2D = $EnterAudio

@export var path_dest: Node
@export var wander_group_name: String = "WanderPosition"

enum CHASER_STATES {STUNNED, IDLE, WANDER, CHASING}
var _current_state : CHASER_STATES = CHASER_STATES.IDLE
var _next_state: CHASER_STATES = _current_state

var movement_speed: float = 70.0
var idle_timer_time: float = 3.0
var movement_target_position: Vector2
var prev_movement_target_position: Vector2
var wander_positions: Array[Node]
var stunned: bool = false

signal started_chasing

func _ready():
	wander_positions = get_tree().get_nodes_in_group(wander_group_name)
	
	movement_target_position = position
	_next_state = CHASER_STATES.IDLE
	enter_audio.play()
	
	
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 3.0
	navigation_agent.target_desired_distance = 3.0

	# Stops await during _ready
	_actor_setup.call_deferred()

func _process(delta: float) -> void:
	if stunned:
		collision.disabled = true
		if !stun_timer.is_stopped():
			_next_state = CHASER_STATES.STUNNED
		else:
			collision.disabled = false
			stunned = false
			_next_state = CHASER_STATES.WANDER
	
	if _current_state != _next_state:
		_current_state = _next_state
	
	match _current_state:
		CHASER_STATES.STUNNED:
			_set_movement_target(position)
		
		CHASER_STATES.IDLE:
			_set_movement_target(position)
			if idle_timer.is_stopped():
				idle_timer.start(idle_timer_time) #seconds
		
		CHASER_STATES.WANDER:
			movement_speed = 30.0
			if navigation_agent.is_target_reached():
				_next_state = CHASER_STATES.IDLE
		
		CHASER_STATES.CHASING:
			if position.distance_to(path_dest.position) > 230.0:
				_next_state = CHASER_STATES.IDLE
			movement_speed = 110.0
			_set_movement_target(path_dest.position)
		
	_audio_anim_matcher()

func _physics_process(delta):
	if navigation_agent.is_navigation_finished():
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * movement_speed
	move_and_slide()

func _actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Now that the navigation map is no longer empty, set the movement target.
	_set_movement_target(movement_target_position)

func _set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target

func _audio_anim_matcher():
	if velocity.x < 0:
		animation.flip_h = false
	if velocity.x > 0:
		animation.flip_h = true
	
	if velocity.length() > 0.5:
		animation.play("Walk")
	else:
		animation.play("Idle")
	
	if _current_state == CHASER_STATES.CHASING:
		animation.speed_scale = 3.5
	else: 
		animation.speed_scale = 1.0


func _on_idle_timer_timeout() -> void:
	if _current_state == CHASER_STATES.CHASING or _current_state == CHASER_STATES.STUNNED:
		return
	
	_next_state = CHASER_STATES.WANDER
	_start_wander()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if _current_state == CHASER_STATES.STUNNED:
		return
	
	_next_state = CHASER_STATES.CHASING
	_start_chase()
	if !idle_timer.is_stopped():
		idle_timer.stop()


func _on_coin_detection_area_entered(area: Area2D) -> void:
	_current_state = CHASER_STATES.STUNNED
	_next_state = _current_state
	
	if !idle_timer.is_stopped():
		idle_timer.stop()
	
	stunned = true
	stun_timer.start(7.5)

func _start_wander():
	wander_positions.sort_custom(_custom_sort_ratio_dist)
	var rand_prob: float = randf()
	
	if rand_prob >= 0.6:
		_set_movement_target(wander_positions[3].position)
	elif rand_prob >= 0.7:
		_set_movement_target(wander_positions[2].position)
	elif rand_prob >= 0.8:
		_set_movement_target(wander_positions[1].position)
	else:
		_set_movement_target(wander_positions[0].position)

func _start_chase():
	if position.distance_to(path_dest.position) > 230.0:
		return
	
	_set_movement_target(path_dest.position)

## UTIL FUNCS
func _custom_sort_ratio_dist(a: Node , b: Node) -> bool:
	var dist_from_a_to_player: float = a.position.distance_to(path_dest.position)
	var dist_from_b_to_player: float = b.position.distance_to(path_dest.position)
	
	return (dist_from_a_to_player < dist_from_b_to_player)


func _on_animated_sprite_2d_frame_changed() -> void:
	if !animation.animation == "Walk":
		return
	
	if (animation.frame == 1) or (animation.frame == 3):
		walk_sound_player.play() 
