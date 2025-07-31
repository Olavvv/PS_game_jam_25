extends AnimationPlayer

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var looped: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	video_stream_player.play()
	audio_stream_player.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_video_stream_player_finished() -> void:
	video_stream_player.play()
	play("fade_out")

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_out":
		get_tree().change_scene_to_file("res://scenes/ui_scenes/main_menu.tscn")
