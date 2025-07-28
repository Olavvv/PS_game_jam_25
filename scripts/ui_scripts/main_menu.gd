extends Control

@onready var start_button: Button = $BoxContainer/VBoxContainer/CenterContainer/VBoxContainer/MarginContainer/Start
@onready var settings_button: Button = $BoxContainer/VBoxContainer/CenterContainer/VBoxContainer/MarginContainer2/Settings
@onready var exit_button: Button = $BoxContainer/VBoxContainer/CenterContainer/VBoxContainer/MarginContainer3/Exit

var main_game := "res://scenes/game.tscn"
var settings_menu := "res://scenes/ui_scenes/settings_menu.tscn"
var user_config_path := "res://user/user_settings.cfg"
var res_settings: Dictionary = {"1280 x 720": Vector2i(1280, 720),
	"1920 x 1080" : Vector2i(1920,1080), 
	"2560 x 1440": Vector2i(2560,1440)}

var config: ConfigFile
func _ready() -> void:
	
	config = ConfigFile.new()
	var error = config.load(user_config_path)
	if error:
		config.save(user_config_path)
	
	# Set audiobus + ui to config file value, or default value
	AudioServer.set_bus_volume_db(0, config.get_value("audio", "master_volume", 50.0) / 5)
	
	# Set display window + uio to config file or default value
	DisplayServer.window_set_size(res_settings.values()[config.get_value("display", "resolution", 0)])
	
	# Set fullscreen or windowed
	DisplayServer.window_set_mode(config.get_value("display", "window_mode", DisplayServer.WINDOW_MODE_WINDOWED))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, config.get_value("display", "borderless_flag", false))
	
	centre_window()
	
	print(config.get_sections())
	print(config.get_section_keys("audio"))
	print(config.get_section_keys("display"))

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("reset_res_window_mode"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		config.set_value("display", "window_mode", DisplayServer.WINDOW_MODE_WINDOWED)
		config.set_value("display", "borderless_flag", false)
		DisplayServer.window_set_size(res_settings.values()[0])
		config.set_value("display", "resolution", 0)
		config.save(user_config_path)

func centre_window():
	var centre_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()/2
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(centre_screen - window_size/2)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(main_game)


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(settings_menu)


func _on_exit_pressed() -> void:
	get_tree().quit()
