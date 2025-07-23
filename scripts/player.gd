extends CharacterBody2D

enum MOVEMENT_STATES {IDLE, IDLE_UP, WALKING, WALKING_UP}

const max_aim_dist_mult = 150.0

## Variables

# Eported vars
@export var SPEED := 150.0
@export var DECEL_SPEED := 50.0
@export var AIM_CIRCLE_RADIUS := 30.0

# Nodes
@onready var aim_circle: Sprite2D = $AimCircle
@onready var animation_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pick_up_range: Area2D = $PickUpRange
@onready var coin_scene := load("res://scenes/items/coin.tscn")
var coin: Area2D

# Coin available?
var has_coin: bool

# Aiming vars
var aim_direction: Vector2
var aim_strength := 0.5
var toss_location := Vector2(0,0)

func _ready() -> void:
	aim_circle.position = Vector2(1,0)
	has_coin = true

func _process(delta: float) -> void:
	aim_point_update()
	coin_pickup()
	queue_redraw()
	

func _physics_process(delta: float) -> void:
	var direction := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")).normalized()
	if direction:
		velocity = (direction * SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, DECEL_SPEED)
		velocity.y = move_toward(velocity.y, 0, DECEL_SPEED)

	move_and_slide()


func coin_pickup() -> void:
	if not coin:
		return
	if coin not in pick_up_range.get_overlapping_areas():
		return
	
	if Input.is_action_just_pressed("pick_up"):
		if coin.pick_up():
			coin = null
			has_coin = true




func aim_point_update() -> void:
	var aim_direction = get_local_mouse_position().normalized()
	var aim_point = (aim_direction * AIM_CIRCLE_RADIUS)
	
	if not has_coin and Input.is_action_pressed("build_strength"):
		print("YOU HAVE NO COIN TO SHOOT")
	
	elif Input.is_action_pressed("build_strength") and has_coin:
		aim_point = aim_point.move_toward(get_local_mouse_position().normalized() * max_aim_dist_mult, aim_strength)
		toss_location = aim_point
		aim_strength += 0.2
	
	elif Input.is_action_just_released("build_strength") and has_coin:
		aim_strength = 0.5
		coin = coin_scene.instantiate()
		get_tree().root.add_child(coin)
		coin.transform = transform
		coin.throw(to_global(toss_location))
		has_coin = false
	
	aim_circle.position = aim_point


func animation_handler():
	pass


## DEBUG
func _draw() -> void:
	if toss_location:
		draw_circle(toss_location, 2.0, Color.RED)
