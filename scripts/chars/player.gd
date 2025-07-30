extends CharacterBody2D

enum MOVEMENT_STATES {IDLE, IDLE_UP, WALKING, WALKING_UP}

const max_aim_dist_mult = 150.0

## Signals

signal died

## Variables
# Eported vars
@export var SPEED := 50.0
@export var DECEL_SPEED := 50.0
@export var AIM_CIRCLE_RADIUS := 30.0

# Nodes
@onready var death_circle: Area2D = $DeathCircle
@onready var aim_circle: Sprite2D = $AimCircle
@onready var animation_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pick_up_range: Area2D = $PickUpRange
@onready var player_glow: PointLight2D = $PointLight2D
@onready var coin_scene := load("res://scenes/items/coin.tscn")
var coin: Area2D
@onready var walking_sound_player: AudioStreamPlayer2D = $WalkingSound

# Bool flags
var has_coin: bool = true
var is_sprinting: bool = false

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
	animation_handler()
	
	## DRAW DEBUG STUFF
	#queue_redraw()

func _physics_process(delta: float) -> void:
	var direction := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")).normalized()
	
	if Input.is_action_pressed("sprint"):
		is_sprinting = true
		if SPEED == 50.0:
			SPEED = SPEED * 2.0
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
	var root = get_tree().get_root()
	var bars = (DisplayServer.screen_get_size() - root.size) / 2
	var corrected_mouse_pos = get_global_mouse_position() - Vector2(bars)
	var aim_direction = to_local(corrected_mouse_pos).normalized()
	var aim_point = (aim_direction * AIM_CIRCLE_RADIUS)
	
	if not has_coin and Input.is_action_pressed("build_strength"):
		print("YOU HAVE NO COIN TO SHOOT")
	
	elif Input.is_action_pressed("build_strength") and has_coin:
		aim_point = aim_point.move_toward(to_local(corrected_mouse_pos).normalized() * max_aim_dist_mult, aim_strength)
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
		animation_sprite.speed_scale = 2.0
	else:
		animation_sprite.speed_scale = 1.0
	
	animation_sprite.flip_h = false # Default statement
	if velocity.x > 0:
		animation_sprite.flip_h = true
		animation_sprite.play("walk_left")
	elif velocity.x < 0:
		animation_sprite.play("walk_left")
	elif velocity.y > 0:
		animation_sprite.play("walk_down")
	elif velocity.y < 0:
		animation_sprite.play("walk_up")
	else:
		animation_sprite.play("idle")



func _on_animated_sprite_2d_frame_changed() -> void:
	if animation_sprite.animation == "idle":
		return
		
	if (animation_sprite.frame == 3) or (animation_sprite.frame == 7):
		walking_sound_player.play()


## DEBUG
func _draw() -> void:
	if toss_location:
		draw_circle(toss_location, 2.0, Color.RED)


func _on_death_circle_body_entered(body: Node2D) -> void:
	if !body.is_in_group("chaser"):
		return
	died.emit()

## EXTERNAL METHODS
func play_walk_up():
	animation_sprite.play("walk_up")
