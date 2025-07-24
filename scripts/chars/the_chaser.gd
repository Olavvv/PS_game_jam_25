extends CharacterBody2D


@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var walk_sound_player: AudioStreamPlayer2D = $WalkSoundPlayer
@export var path_dest: Node

var movement_speed: float = 200.0
var movement_target_position: Vector2

func _ready():
	movement_target_position = path_dest.position
	
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 3.0
	navigation_agent.target_desired_distance = 3.0

	# Stops await during _ready
	_actor_setup.call_deferred()

func _process(delta: float) -> void:
	_set_movement_target(path_dest.position)

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
	if velocity.length() > 0.5:
		walk_sound_player.play()
