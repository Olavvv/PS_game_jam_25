extends CharacterBody2D

enum MOVEMENT_STATES {IDLE, IDLE_UP, WALKING, WALKING_UP}

const SPEED = 300.0
const DECEL_SPEED = 50.0
const JUMP_VELOCITY = -400.0

var animation_sprite: AnimatedSprite2D

func _ready() -> void:
	animation_sprite = $AnimatedSprite2D
	
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Vector2(Input.get_axis("ui_right", "ui_left"), Input.get_axis("ui_down", "ui_up")).normalized()
	if direction:
		velocity = (direction * SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, DECEL_SPEED)
		velocity.y = move_toward(velocity.y, 0, DECEL_SPEED)

	move_and_slide()


func animation_handler():
	if (velocity.x < 0):
		animation_sprite.play()
