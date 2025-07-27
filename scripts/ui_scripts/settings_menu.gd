extends Control

@onready var volume_slider: HSlider = $MarginContainer/CenterContainer/VBoxContainer/MarginContainer/HBoxContainer/Volume
@onready var volume_prog_label: Label = $MarginContainer/CenterContainer/VBoxContainer/MarginContainer/HBoxContainer/Label2
@onready var return_button: Button = $MarginContainer/CenterContainer/VBoxContainer/MarginContainer2/ReturnButton

var main_menu := "res://scenes/ui_scenes/main_menu.tscn"
var user_config_path := "res://user/user_settings.cfg"

var config: ConfigFile
func _ready() -> void:
	config = ConfigFile.new()
	var error = config.load(user_config_path)
	if !error:
		AudioServer.set_bus_volume_db(0, config.get_value("audio", "master_volume", 0.0) / 5)
		volume_prog_label.text = str(int(config.get_value("audio", "master_volume", 0.0)))
		volume_slider.value = config.get_value("audio", "master_volume", 0.0)

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file(main_menu)

func _on_volume_value_changed(value: float) -> void:
	volume_prog_label.text = str(int(volume_slider.value))
	AudioServer.set_bus_volume_db(0, volume_slider.value / 5)
	config.set_value("audio", "master_volume", volume_slider.value)
	config.save(user_config_path)
