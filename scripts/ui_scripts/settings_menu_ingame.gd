extends CanvasLayer

@onready var volume_slider: HSlider = $SettingsMenu/MarginContainer/CenterContainer/VBoxContainer/MarginContainer/HBoxContainer/Volume
@onready var volume_prog_label: Label = $SettingsMenu/MarginContainer/CenterContainer/VBoxContainer/MarginContainer/HBoxContainer/Label2
@onready var return_button: Button = $SettingsMenu/MarginContainer/CenterContainer/VBoxContainer/MarginContainer2/ReturnButton
@onready var res_menu: OptionButton = $SettingsMenu/MarginContainer/CenterContainer/VBoxContainer/MarginContainer3/HBoxContainer/Resolution
@onready var res_check: CheckButton = $SettingsMenu/MarginContainer/CenterContainer/VBoxContainer/MarginContainer4/HBoxContainer/CheckButton

signal unpause

var main_menu := "res://scenes/ui_scenes/main_menu.tscn"
var game_scene := "res://scenes/game.tscn"
var user_config_path := "res://user/user_settings.cfg"
var is_game_paused: bool = false
var res_settings: Dictionary = {"1280 x 720": Vector2i(1280, 720),
	"1920 x 1080" : Vector2i(1920,1080), 
	"2560 x 1440": Vector2i(2560,1440)}

var config: ConfigFile
func _ready() -> void:
	config = ConfigFile.new()
	var error = config.load(user_config_path)
	if error:
		config.save(user_config_path)
	
	_add_items_resolution()
	
	# Set audiobus + ui to config file value, or default value
	volume_prog_label.text = str(int(config.get_value("audio", "master_volume", 50.0)))
	volume_slider.value = config.get_value("audio", "master_volume", 50.0)
	
	# Set display window + uio to config file or default value
	res_menu.selected = config.get_value("display", "resolution", 0)
	
	# Set fullscreen or windowed
	res_check.button_pressed = config.get_value("display", "window_mode", 0) if config.get_value("display", "window_mode", 0) == 0 else 1

func _process(delta: float) -> void:
	if res_check.button_pressed:
		res_menu.disabled = true
	else:
		res_menu.disabled = false

func _add_items_resolution():
	for res in res_settings:
		res_menu.add_item(res)

func _refresh():
	# Set audiobus + ui to config file value, or default value
	AudioServer.set_bus_volume_db(0, config.get_value("audio", "master_volume", 50.0) / 5)
	
	# Set display window + uio to config file or default value
	DisplayServer.window_set_size(res_settings.values()[config.get_value("display", "resolution", 0)])
	
	# Set fullscreen or windowed
	DisplayServer.window_set_mode(config.get_value("display", "window_mode", DisplayServer.WINDOW_MODE_WINDOWED))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, config.get_value("display", "borderless_flag", false))
	centre_window()

func centre_window():
	var centre_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()/2
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(centre_screen - window_size/2)

func _on_return_button_pressed() -> void:
	unpause.emit()
	queue_free()

func _on_volume_value_changed(value: float) -> void:
	volume_prog_label.text = str(int(volume_slider.value))
	AudioServer.set_bus_volume_db(0, volume_slider.value / 5)
	config.set_value("audio", "master_volume", volume_slider.value)
	config.save(user_config_path)

func _on_resolution_item_selected(index: int) -> void:
	DisplayServer.window_set_size(res_settings.values()[index])
	config.set_value("display", "resolution", index)
	config.save(user_config_path)
	_refresh()

func _on_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		config.set_value("display", "window_mode", DisplayServer.WINDOW_MODE_FULLSCREEN)
		config.set_value("display", "borderless_flag", true)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		config.set_value("display", "window_mode", DisplayServer.WINDOW_MODE_WINDOWED)
		config.set_value("display", "borderless_flag", false)
	config.save(user_config_path)
	_refresh()


func _on_main_menu_button_pressed() -> void:
	get_tree().quit()
