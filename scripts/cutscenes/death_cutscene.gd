extends AnimationPlayer

@onready var chaser_anim: AnimatedSprite2D = $ChaserAnim

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chaser_anim.play("Death")
	play("die")


func _on_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
