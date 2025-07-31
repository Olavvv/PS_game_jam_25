extends AnimationPlayer

@onready var player_anim: AnimatedSprite2D = $PlayerAnim
@onready var player_walk_sound: AudioStreamPlayer2D = $PlayerAnim/AudioStreamPlayer2D


func _on_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://scenes/ui_scenes/main_menu.tscn")


func _on_player_anim_frame_changed() -> void:
	if (player_anim.frame == 3) or (player_anim.frame == 7):
		player_walk_sound.play()
