extends CharacterBody2D

enum MOVEMENT_STATES {IDLE, IDLE_UP, WALKING, WALKING_UP}

const max_aim_dist_mult = 150.0

## Variables

# Eported vars
@export var SPEED := 50.0
@export var DECEL_SPEED := 50.0
@export var AIM_CIRCLE_RADIUS := 30.0

# Nodes
@onready var aim_circle: Sprite2D = $AimCircle
@onready var animation_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pick_up_range: Area2D = $PickUpRange
@onready var player_glow: PointLight2D = $PointLight2D
@onready var coin_scene := load("res://scenes/items/coin.tscn")
var coin: Area2D
@onready var light_change_timer: Timer  = $Timer
@onready var walking_sound_player: AudioStreamPlayer2D = $WalkingSound

# Bool flags
var has_coin: bool
var is_sprinting: bool = false

# Aiming vars
var aim_direction: Vector2
var aim_strength := 0.5
var toss_location := Vector2(0,0)

## Light vars
@onready var light_images:= [load("res://assets/sprites/textures/lantern_light/light_texture_1.png"), load("res://assets/sprites/textures/lantern_light/light_texture_2.png")]


func _ready() -> void:
	aim_circle.position = Vector2(1,0)
	has_coin = true
	light_change_timer.timeout.connect(_on_light_timer_timeout)
	player_glow.texture = light_images[0]
	light_change_timer.start(1.0) # Timer set to 1 sec

func _process(delta: float) -> void:
	aim_point_update()
	coin_pickup()
	queue_redraw()
	animation_handler()
	

func _physics_process(delta: float) -> void:
	var direction := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")).normalized()
	
	if Input.is_action_pressed("sprint"):
		is_sprinting = true
		if SPEED == 50.0:
			SPEED = SPEED * 1.5
	else:
		is_sprinting = false
		SPEED = 50.0
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
	if is_sprinting:
		animation_sprite.speed_scale = 1.5
	else:
		animation_sprite.speed_scale = 1.0
	
	animation_sprite.flip_h = false # Default statement
	if velocity.x > 0:
		animation_sprite.play("move_sideways")
	elif velocity.x < 0:
		animation_sprite.play("move_sideways")
		animation_sprite.flip_h = true
	elif velocity.y > 0:
		animation_sprite.play("move_down")
	elif velocity.y < 0:
		animation_sprite.play("move_up")
	else:
		animation_sprite.play("idle")



## SIGNAL HANDLERS

func _on_light_timer_timeout() -> void:
	if player_glow.texture == light_images[0]:
		player_glow.texture = light_images[1]
	else:
		player_glow.texture = light_images[0]
	light_change_timer.start(1.0)

func _on_animated_sprite_2d_frame_changed() -> void:
	if animation_sprite.animation == "idle":
		return
		
	if ((animation_sprite.frame % 2) == 0) and (animation_sprite.frame != 0):
		print(animation_sprite.frame)
		walking_sound_player.play()

## DEBUG
func _draw() -> void:
	if toss_location:
		draw_circle(toss_location, 2.0, Color.RED)
