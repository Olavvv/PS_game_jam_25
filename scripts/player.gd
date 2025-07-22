extends CharacterBody2D

enum MOVEMENT_STATES {IDLE, IDLE_UP, WALKING, WALKING_UP}

@export var SPEED = 300.0
@export var DECEL_SPEED = 50.0
@export var AIM_CIRCLE_RADIUS = 30.0

const max_aim_dist_mult = 150.0

var animation_sprite: AnimatedSprite2D
var coin: RigidBody2D

# Aiming vars
var aim_circle: Sprite2D
var aim_direction: Vector2
var aim_strength = 0.5
var toss_location = Vector2(0,0)

func _ready() -> void:
	coin = $Coin
	animation_sprite = $AnimatedSprite2D
	aim_circle = $AimCircle
	aim_circle.position = Vector2(1,0)
	
	
func _process(delta: float) -> void:
	aim_point_update()
	queue_redraw()
	

func _physics_process(delta: float) -> void:
	var direction := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")).normalized()
	if direction:
		velocity = (direction * SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, DECEL_SPEED)
		velocity.y = move_toward(velocity.y, 0, DECEL_SPEED)

	move_and_slide()

func aim_point_update() -> void:
	var aim_direction = get_local_mouse_position().normalized()
	var aim_point = (aim_direction * AIM_CIRCLE_RADIUS)
	
	if Input.is_action_pressed("build_strength"):
		aim_point = aim_point.move_toward(get_local_mouse_position().normalized() * max_aim_dist_mult, aim_strength)
		toss_location = aim_point
		aim_strength += 0.2
		
	elif Input.is_action_just_released("build_strength"):
		aim_strength = 0.5
		coin.throw()
		print(toss_location)
	
	aim_circle.position = aim_point

func _draw() -> void:
	if toss_location:
		draw_circle(toss_location, 2.0, Color.RED)

func animation_handler():
	pass
