extends Area2D

signal flag_event

func _on_body_entered(body: Node2D) -> void:
	flag_event.emit()
