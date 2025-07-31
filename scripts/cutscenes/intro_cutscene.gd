extends AnimationPlayer

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	video_stream_player.play()

func _on_video_stream_player_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
