extends Node

var user_config_path := "res://user/user_settings.cfg"


var config: ConfigFile
func _ready() -> void:
	config = ConfigFile.new()
	var error = config.load(user_config_path)
	if !error:
		AudioServer.set_bus_volume_db(0, config.get_value("audio", "master_volume", 0.0) / 5)
