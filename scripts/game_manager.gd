extends Node

var user_config_path := "res://user/user_settings.cfg"
var ingame_settings_menu: PackedScene = load("res://scenes/ui_scenes/settings_menu_ingame.tscn")
var settings_scene

var config: ConfigFile
func _ready() -> void:
	
	config = ConfigFile.new()
	var error = config.load(user_config_path)
	if !error:
		AudioServer.set_bus_volume_db(0, config.get_value("audio", "master_volume", 0.0) / 5)


func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("open_settings"):
		settings_scene = ingame_settings_menu.instantiate()
		add_child(settings_scene)
		get_tree().paused = true

	
