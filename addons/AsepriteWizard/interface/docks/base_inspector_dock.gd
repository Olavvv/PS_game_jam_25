@tool
extends PanelContainer

const wizard_config = preload("../../config/wizard_config.gd")
const result_code = preload("../../config/result_codes.gd")
var _aseprite_file_exporter = preload("../../aseprite/file_exporter.gd").new()
var config = preload("../../config/config.gd").new()

var scene: Node
var target_node: Node
var file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()

var _slice: String = ""
var _source_uid: int = -1
var _source: String = ""
var _file_dialog_aseprite: EditorFileDialog
var _output_folder_dialog: EditorFileDialog
var _importing := false
var _output_folder := ""
var _out_folder_default := "[Same as scene]"
var _layer_default := "[all]"

var _output_filename_text := "File Name"
var _output_filename_prefix_text := "File Name Prefix"

var _interface_section_state

@onready var _section_title := $dock_fields/VBoxContainer/title as Button

# general
@onready var _source_field := $dock_fields/VBoxContainer/source/button as Button
# layers
@onready var _layer_section_header := $dock_fields/VBoxContainer/extra/sections/layers/section_header as Button
@onready var _layer_section_container := $dock_fields/VBoxContainer/extra/sections/layers/section_content as MarginContainer
@onready var _layer_field := $dock_fields/VBoxContainer/extra/sections/layers/section_content/content/layer/options as VBoxContainer
@onready var _visible_layers_field :=  $dock_fields/VBoxContainer/extra/sections/layers/section_content/content/visible_layers/CheckBox as CheckBox
@onready var _ex_pattern_field := $dock_fields/VBoxContainer/extra/sections/layers/section_content/content/ex_pattern/LineEdit as LineEdit
# slice
@onready var _slice_section_header := $dock_fields/VBoxContainer/extra/sections/slices/section_header as Button
@onready var _slice_section_container := $dock_fields/VBoxContainer/extra/sections/slices/section_content as MarginContainer
@onready var _slice_field := $dock_fields/VBoxContainer/extra/sections/slices/section_content/content/slice/options as OptionButton
# output
@onready var _output_section_header := $dock_fields/VBoxContainer/extra/sections/output/section_header as Button
@onready var _output_section_container := $dock_fields/VBoxContainer/extra/sections/output/section_content as MarginContainer
@onready var _out_folder_field := $dock_fields/VBoxContainer/extra/sections/output/section_content/content/out_folder/button as Button
@onready var _out_folder_container := $dock_fields/VBoxContainer/extra/sections/output/section_content/content/out_folder as HBoxContainer

@onready var _out_filename_field := $dock_fields/VBoxContainer/extra/sections/output/section_content/content/out_filename/LineEdit as LineEdit
@onready var _out_filename_label := $dock_fields/VBoxContainer/extra/sections/output/section_content/content/out_filename/Label as Label
@onready var _out_filename_container := $dock_fields/VBoxContainer/extra/sections/output/section_content/content/out_filename as HBoxContainer

@onready var _embed_label := $dock_fields/VBoxContainer/extra/sections/output/section_content/content/embed/Label as Label
@onready var _embed_field :=  $dock_fields/VBoxContainer/extra/sections/output/section_content/content/embed/CheckBox as CheckBox

@onready var _scale_field :=  $dock_fields/VBoxContainer/extra/sections/output/section_content/content/scale/SpinBox as SpinBox


@onready var _import_button := $dock_fields/VBoxContainer/import as Button

const INTERFACE_SECTION_KEY_LAYER = "layer_section"
const INTERFACE_SECTION_KEY_SLICE = "slice_section"
const INTERFACE_SECTION_KEY_OUTPUT = "output_section"

@onready var _expandable_sections = {
	INTERFACE_SECTION_KEY_LAYER: { "header": _layer_section_header, "content": _layer_section_container},
	INTERFACE_SECTION_KEY_SLICE: { "header": _slice_section_header, "content": _slice_section_container},
	INTERFACE_SECTION_KEY_OUTPUT: { "header": _output_section_header, "content": _output_section_container},
}

const PENDING_CHANGES_KEY := "pending_changes"

var _do_not_update_pending := false

func _ready():
	_pre_setup()
	_setup_interface()
	_setup_config()
	_setup_field_listeners()
	_setup()
	_check_for_changes()
	_check_for_field_changes()


func _check_for_changes():
	if not _source or _source == "":
		return

	var saved_hash = wizard_config.get_source_hash(target_node)

	if saved_hash == "":
		return

	if saved_hash != FileAccess.get_md5(_source):
		$dock_fields.show_source_change_warning()


func _check_for_field_changes():
	var cfg = wizard_config.load_config(target_node)
	var changed = _get_changed_config(cfg)

	if changed == null or changed.is_empty():
		$dock_fields.hide_fields_change_warning()
		_interface_section_state[PENDING_CHANGES_KEY] = {}
	else:
		if cfg != null and not cfg.is_empty(): # has saved data
			$dock_fields.show_fields_change_warning()
		_interface_section_state[PENDING_CHANGES_KEY] = changed


func _update_pending_fields():
	if _do_not_update_pending:
		return

	_check_for_field_changes()
	wizard_config.save_interface_config(target_node, _interface_section_state)


func _get_changed_config(saved_config):
	var current = _get_current_config()

	if saved_config == null:
		return current if current != null else {}

	if current == null:
		return {}

	var changed := {}

	for c in current:
		if saved_config.get(c) != current[c]:
			changed[c] = current[c]

	return changed


func _setup_interface():
	_hide_fields()
	_show_specific_fields()
	var cfg = wizard_config.load_interface_config(target_node)
	_interface_section_state = cfg

	_section_title.add_theme_stylebox_override("normal", _section_title.get_theme_stylebox("hover"))

	for key in _expandable_sections:
		_adjust_section_visibility(key)


func _load_persisted_config() -> Dictionary:
	var cfg = wizard_config.load_config(target_node)
	var persisted = {}
	if cfg == null:
		persisted = {}
	else:
		persisted = cfg.duplicate()

	var changed = _interface_section_state.get(PENDING_CHANGES_KEY, {})

	for c in changed:
		persisted[c] = changed[c]

	return persisted


func _setup_config():
	var cfg = _load_persisted_config()

	if cfg.is_empty():
		_load_common_default_config()
	else:
		_load_common_config(cfg)


func _load_common_config(cfg):
	if cfg.has("source"):
		_set_source(cfg.source, cfg.get("source_uid", -1))

	# keeping this to be backwards compatible
	if cfg.get("layer", "") != "":
		_layer_field.set_selected_layers([cfg.layer])
		_update_pending_fields()
		_out_filename_label.text = _output_filename_prefix_text
	else:
		var layers = cfg.get("layers", [])
		_layer_field.set_selected_layers(layers)
		if layers.size() > 0:
			_update_pending_fields()
		if layers.size() == 1:
			_out_filename_label.text = _output_filename_prefix_text

	if cfg.get("slice", "") != "":
		_slice_field.clear()
		_set_slice(cfg.slice)
	else:
		_slice = ""
		_slice_field.select(0)

	_set_out_folder(cfg.get("o_folder", ""))
	_out_filename_field.text = cfg.get("o_name", "")
	_visible_layers_field.button_pressed = cfg.get("only_visible", false)
	_ex_pattern_field.text = cfg.get("o_ex_p", "")

	_embed_field.button_pressed = cfg.get("embed_tex", false)
	_scale_field.value = float(cfg.get("scale", 1))

	_load_config(cfg)
	_handle_embed_visibility()


func _load_common_default_config():
	_ex_pattern_field.text = config.get_default_exclusion_pattern()
	_visible_layers_field.button_pressed = config.should_include_only_visible_layers_by_default()
	#_cleanup_hide_unused_nodes.button_pressed = config.is_set_visible_track_automatically_enabled()
	_load_default_config()


func _set_source(source, uid: int = -1):
	if uid == -1 or not ResourceUID.has_id(uid):
		if ResourceLoader.exists(source):
			_source_uid = ResourceLoader.get_resource_uid(source)
	else:
		_source_uid = uid
		var source_path = ResourceUID.get_id_path(uid)
		_set_source_fields(source_path)
		return

	_set_source_fields(source)


func _set_source_fields(source):
	_source = source
	_source_field.text = _source
	_source_field.tooltip_text = _source
	_update_pending_fields()


func _set_slice(slice):
	_slice = slice
	_slice_field.add_item(_slice)
	_update_pending_fields()


func _set_out_folder(path):
	_output_folder = path
	_out_folder_field.text = _output_folder if _output_folder != "" else _out_folder_default
	_out_folder_field.tooltip_text = _out_folder_field.text
	_update_pending_fields()


func _toggle_section_visibility(key: String) -> void:
	_interface_section_state[key] = not _interface_section_state.get(key, false)
	_adjust_section_visibility(key)
	wizard_config.save_interface_config(target_node, _interface_section_state)


func _adjust_section_visibility(key: String) -> void:
	var section = _expandable_sections[key]
	var is_visible = _interface_section_state.get(key, false)
	_adjust_icon(section.header, is_visible)
	section.content.visible = is_visible


func _adjust_icon(section: Button, is_visible: bool = true) -> void:
	var icon_name = "GuiTreeArrowDown" if is_visible else "GuiTreeArrowRight"
	section.icon = get_theme_icon(icon_name, "EditorIcons")


func _setup_field_listeners():
	_layer_section_header.button_down.connect(_on_layer_header_button_down)
	_slice_section_header.button_down.connect(_on_slice_header_button_down)
	_output_section_header.button_down.connect(_on_output_header_button_down)

	_source_field.pressed.connect(_on_source_pressed)
	_source_field.aseprite_file_dropped.connect(_on_source_aseprite_file_dropped)

	_layer_field.data_fetcher = _fetch_layers
	_layer_field.value_changed.connect(_on_layer_value_changed)

	_slice_field.button_down.connect(_on_slice_button_down)
	_slice_field.item_selected.connect(_on_slice_item_selected)

	_out_folder_field.dir_dropped.connect(_on_out_dir_dropped)
	_out_folder_field.pressed.connect(_on_out_folder_pressed)

	_import_button.pressed.connect(_on_import_pressed)

	_embed_field.pressed.connect(_on_embed_button_pressed)


func _on_layer_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_LAYER)


func _on_slice_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_SLICE)


func _on_output_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_OUTPUT)


func _fetch_layers():
	if _source == "":
		_show_message("Please. Select source file first.")
		return

	return _get_available_layers(ProjectSettings.globalize_path(_source))


func _on_layer_value_changed():
	var layers: Array = _layer_field.get_selected_layers()

	if layers.size() == 1:
		_out_filename_label.text = _output_filename_prefix_text
		_update_pending_fields()
		return

	_out_filename_label.text = _output_filename_text
	_update_pending_fields()


func _on_slice_item_selected(index):
	if index == 0:
		_slice = ""
		return
	_slice = _slice_field.get_item_text(index)
	_update_pending_fields()


func _on_slice_button_down():
	if _source == "":
		_show_message("Please, select source file first.")
		return

	var slices = _get_available_slices(ProjectSettings.globalize_path(_source))
	var current = 0
	_slice_field.clear()
	_slice_field.add_item(_layer_default)

	for s in slices:
		if s == "":
			continue

		_slice_field.add_item(s)
		if s == _slice:
			current = _slice_field.get_item_count() - 1
	_slice_field.select(current)


func _on_source_pressed():
	_open_source_dialog()


func _get_current_config():
	var child_config = _get_current_field_values()

	var cfg := {
		"source": _source,
		"source_uid": _source_uid,
		"layers": _layer_field.get_selected_layers(),
		"slice": _slice,
		"o_folder": _output_folder,
		"o_name": _out_filename_field.text,
		"only_visible": _visible_layers_field.button_pressed,
		"o_ex_p": _ex_pattern_field.text,
		"embed_tex": _embed_field.button_pressed,
		"scale": str(_scale_field.value),
	}

	for c in child_config:
		cfg[c] = child_config[c]

	return cfg


##
## Save current import options to node metadata
##
func _save_config():
	wizard_config.save_config(target_node, _get_current_config())
	_update_pending_fields()
	EditorInterface.mark_scene_as_unsaved()


func _get_import_options(default_folder: String):
	return {
		"output_folder": _output_folder if _output_folder != "" else default_folder,
		"exception_pattern": _ex_pattern_field.text,
		"only_visible_layers": _visible_layers_field.button_pressed,
		"output_filename": _out_filename_field.text,
		"layers": _layer_field.get_selected_layers(),
		"embed_tex": _embed_field.button_pressed,
		"scale": str(_scale_field.value),
	}


func _open_source_dialog():
	_file_dialog_aseprite = _create_aseprite_file_selection()
	get_parent().add_child(_file_dialog_aseprite)
	if _source != "":
		_file_dialog_aseprite.current_dir = ProjectSettings.globalize_path(_source.get_base_dir())
	_file_dialog_aseprite.popup_centered_ratio()


func _create_aseprite_file_selection():
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.connect("file_selected",Callable(self,"_on_aseprite_file_selected"))
	file_dialog.set_filters(PackedStringArray(["*.ase","*.aseprite"]))
	return file_dialog


func _on_aseprite_file_selected(path):
	_set_source(ProjectSettings.localize_path(path))
	_update_pending_fields()
	_file_dialog_aseprite.queue_free()


func _on_source_aseprite_file_dropped(path):
	_set_source(path)
	_update_pending_fields()


## Helper method to populate field with values
func _populate_options_field(field: OptionButton, values: Array, current_name: String):
	var current = 0
	field.clear()
	field.add_item("[all]")

	for v in values:
		if v == "":
			continue

		field.add_item(v)
		if v == current_name:
			current = field.get_item_count() - 1
	field.select(current)


func _on_out_folder_pressed():
	_output_folder_dialog = _create_output_folder_selection()
	get_parent().add_child(_output_folder_dialog)
	if _output_folder != _out_folder_default:
		_output_folder_dialog.current_dir = _output_folder
	_output_folder_dialog.popup_centered_ratio()


func _create_output_folder_selection():
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialog.connect("dir_selected",Callable(self,"_on_output_folder_selected"))
	return file_dialog


func _on_output_folder_selected(path):
	_set_out_folder(path)
	_output_folder_dialog.queue_free()
	_update_pending_fields()


func _on_out_dir_dropped(path):
	_set_out_folder(path)
	_update_pending_fields()


func _on_embed_button_pressed():
	_handle_embed_visibility()


func _handle_embed_visibility():
	if _embed_field.button_pressed:
		_out_folder_container.hide()
		_out_filename_container.hide()
	else:
		_out_folder_container.show()
		_out_filename_container.show()


func _show_message(message: String):
	var _warning_dialog = AcceptDialog.new()
	get_parent().add_child(_warning_dialog)
	_warning_dialog.dialog_text = message
	_warning_dialog.popup_centered()
	_warning_dialog.canceled.connect(_warning_dialog.queue_free)
	_warning_dialog.confirmed.connect(_warning_dialog.queue_free)


func _notify_aseprite_error(aseprite_error_code):
	var error = result_code.get_error_message(aseprite_error_code)
	printerr(error)
	_show_message(error)


func _handle_cleanup(aseprite_content, should_remove_spritesheet = false):
	if config.should_remove_source_files():
		DirAccess.remove_absolute(aseprite_content.data_file)
		if should_remove_spritesheet:
			DirAccess.remove_absolute(aseprite_content.sprite_sheet)
			var import_file = "%s.import" % aseprite_content.sprite_sheet
			if FileAccess.file_exists(import_file):
				DirAccess.remove_absolute(import_file)

		file_system.call_deferred("scan")


func _on_import_pressed():
	if _importing:
		return
	_importing = true

	if _source == "":
		_show_message("Aseprite file not selected")
		_importing = false
		return

	if get_tree().get_edited_scene_root().scene_file_path == "":
		_show_message("Scene needs to be saved at least once before importing animations")
		_importing = false
		return

	await _do_import()
	_importing = false
	$dock_fields.hide_source_change_warning()
	EditorInterface.save_scene()



# This is a little bit leaky as this base scene contains fields only relevant to animation players.
# However, this is the simplest thing I can do without overcomplicating stuff.
func _hide_fields():
	$dock_fields/VBoxContainer/modes.hide()
	$dock_fields/VBoxContainer/animation_player.hide()
	$dock_fields/VBoxContainer/extra/sections/animation.hide()
	$dock_fields/VBoxContainer/extra/sections/animation_sf.hide()


func _on_dock_fields_revert_changes_requested() -> void:
	$dock_fields.disable_change_notification = true
	_do_not_update_pending = true
	_interface_section_state[PENDING_CHANGES_KEY] = {}
	wizard_config.save_interface_config(target_node, _interface_section_state)
	_setup_config()
	$dock_fields.disable_change_notification = false
	$dock_fields.hide_fields_change_warning()
	_do_not_update_pending = false
	EditorInterface.mark_scene_as_unsaved()


func _on_dock_fields_field_changed() -> void:
	_check_for_field_changes()


## this will be called before base class does its setup
func _pre_setup():
	pass


## this will be called after base class setup is complete
func _setup():
	pass


func _load_default_config():
	pass


func _load_config(cfg: Dictionary):
	pass


## Override to return available layers
func _get_available_layers(global_source_path: String) -> Array:
	return []


## Override to return available slices
func _get_available_slices(global_source_path: String) -> Array:
	return []


## Override this method for extra import options to add to node metadata
func _get_current_field_values() -> Dictionary:
	return {}


func _do_import():
	pass


func _show_specific_fields() -> void:
	pass
