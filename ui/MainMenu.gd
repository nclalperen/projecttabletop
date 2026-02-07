extends Control

@onready var _banner: Node = $StatusBanner
@onready var _start_button: Button = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/StartButton
@onready var _settings_button: Button = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/SettingsButton
@onready var _quit_button: Button = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/QuitButton
@onready var _menu_card: PanelContainer = $CenterContainer/MenuCard
@onready var _settings_summary: Label = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/SettingsSummary

# Game configuration
var player_count: int = 4
var game_seed: int = -1  # -1 means random
var rule_config: RuleConfig = null
var _animations_enabled: bool = true

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Welcome to Okey 101!")

	# Initialize default config
	rule_config = RuleConfig.new()
	_refresh_settings_summary()
	_bind_button_feedback()
	_animate_menu_in()

func _animate_menu_in() -> void:
	if not _animations_enabled or _menu_card == null:
		return
	_menu_card.modulate = Color(1, 1, 1, 0)
	_menu_card.position.y += 24
	var tween = create_tween()
	tween.tween_property(_menu_card, "modulate", Color(1, 1, 1, 1), 0.25)
	tween.parallel().tween_property(_menu_card, "position:y", _menu_card.position.y - 24, 0.25)

func _bind_button_feedback() -> void:
	var buttons = [_start_button, _settings_button, _quit_button]
	for b in buttons:
		if b == null:
			continue
		b.button_down.connect(func(): b.scale = Vector2(1.05, 1.05))
		b.button_up.connect(func(): b.scale = Vector2(1, 1))

func _on_start_pressed() -> void:
	# Generate random seed if not set
	var actual_seed: int = game_seed if game_seed >= 0 else randi()

	# Load GameTable scene and pass configuration
	var game_table_scene: PackedScene = load("res://ui/GameTable.tscn")
	var game_table: Node = game_table_scene.instantiate()

	# Set game configuration if GameTable has methods for it
	if game_table.has_method("configure_game"):
		game_table.configure_game(rule_config, actual_seed, player_count)
	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Starting game (%s players, %s seed)" % [player_count, "random" if game_seed < 0 else str(game_seed)])

	# Switch to game scene
	if _animations_enabled:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_callback(func():
			get_tree().root.add_child(game_table)
			queue_free()
		)
	else:
		get_tree().root.add_child(game_table)
		queue_free()

func _on_settings_pressed() -> void:
	_show_settings_dialog()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _show_settings_dialog() -> void:
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Game Settings"
	dialog.ok_button_text = "Apply"
	dialog.cancel_button_text = "Cancel"
	var menu_theme: Theme = load("res://ui/themes/okey_theme.tres")
	if menu_theme != null:
		dialog.theme = menu_theme
	dialog.custom_minimum_size = Vector2(520, 420)

	# Create container for settings
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(480, 320)
	vbox.separation = 12

	# Section: Players
	var section_players: Label = Label.new()
	section_players.text = "Players"
	section_players.add_theme_color_override("font_color", Color(0.12, 0.28, 0.33))
	section_players.add_theme_font_size_override("font_size", 20)
	vbox.add_child(section_players)

	var player_label: Label = Label.new()
	player_label.text = "Number of Players:"
	player_label.add_theme_color_override("font_color", Color(0.12, 0.28, 0.33))
	player_label.tooltip_text = "Choose how many players will join the round (2 to 4)."
	vbox.add_child(player_label)

	var player_row: HBoxContainer = HBoxContainer.new()
	player_row.separation = 8
	var player_minus: Button = Button.new()
	player_minus.text = "−"
	player_minus.custom_minimum_size = Vector2(60, 60)
	var player_value: Label = Label.new()
	player_value.text = str(player_count)
	player_value.custom_minimum_size = Vector2(60, 44)
	player_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_value.add_theme_font_size_override("font_size", 18)
	var player_plus: Button = Button.new()
	player_plus.text = "+"
	player_plus.custom_minimum_size = Vector2(60, 60)
	player_row.add_child(player_minus)
	player_row.add_child(player_value)
	player_row.add_child(player_plus)
	vbox.add_child(player_row)

	var player_preview: HBoxContainer = HBoxContainer.new()
	player_preview.separation = 6
	for i in range(4):
		var badge := Label.new()
		badge.text = "?"
		badge.custom_minimum_size = Vector2(24, 24)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		player_preview.add_child(badge)
	vbox.add_child(player_preview)

	vbox.add_child(Control.new())  # Spacer

	# Section: Seed
	var section_seed: Label = Label.new()
	section_seed.text = "Random Seed"
	section_seed.add_theme_color_override("font_color", Color(0.12, 0.28, 0.33))
	section_seed.add_theme_font_size_override("font_size", 20)
	vbox.add_child(section_seed)

	var seed_label: Label = Label.new()
	seed_label.text = "Seed Value:"
	seed_label.add_theme_color_override("font_color", Color(0.12, 0.28, 0.33))
	seed_label.tooltip_text = "Use a fixed seed for repeatable games, or enable Random Seed."
	vbox.add_child(seed_label)

	var seed_row: HBoxContainer = HBoxContainer.new()
	seed_row.separation = 8
	var random_seed_check: CheckBox = CheckBox.new()
	random_seed_check.text = "Random Seed"
	random_seed_check.tooltip_text = "When enabled, a new random seed is used each round."
	seed_row.add_child(random_seed_check)
	vbox.add_child(seed_row)

	var seed_spin: SpinBox = SpinBox.new()
	seed_spin.min_value = 0
	seed_spin.max_value = 999999
	seed_spin.value = max(0, game_seed)
	seed_spin.step = 1
	seed_spin.custom_minimum_size = Vector2(260, 60)
	vbox.add_child(seed_spin)

	vbox.add_child(Control.new())  # Spacer

	# Info label
	var info_label: Label = Label.new()
	info_label.text = "Note: More rule settings coming soon!"
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info_label)

	dialog.add_child(vbox)

	var apply_button: Button = dialog.get_ok_button()
	var cancel_button: Button = dialog.get_cancel_button()
	apply_button.add_theme_font_size_override("font_size", 18)
	cancel_button.add_theme_font_size_override("font_size", 18)
	apply_button.custom_minimum_size = Vector2(140, 60)
	cancel_button.custom_minimum_size = Vector2(140, 60)

	# Connect buttons
	dialog.confirmed.connect(func():
		player_count = int(player_value.text)
		game_seed = -1 if random_seed_check.button_pressed else int(seed_spin.value)
		_refresh_settings_summary()
		if _banner != null and _banner.has_method("set_text"):
			_banner.call("set_text", "Settings updated (%s players, %s seed)" % [player_count, "random" if game_seed < 0 else str(game_seed)])
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())

	add_child(dialog)
	dialog.popup_centered()

	var refresh_player_preview = func(count: int) -> void:
		for i in range(player_preview.get_child_count()):
			var badge: Label = player_preview.get_child(i)
			if i < count:
				badge.add_theme_color_override("font_color", Color(0.2, 0.45, 0.6))
			else:
				badge.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	player_minus.pressed.connect(func():
		var value = clamp(int(player_value.text) - 1, 2, 4)
		player_value.text = str(value)
		refresh_player_preview.call(value)
	)
	player_plus.pressed.connect(func():
		var value = clamp(int(player_value.text) + 1, 2, 4)
		player_value.text = str(value)
		refresh_player_preview.call(value)
	)
	random_seed_check.toggled.connect(func(pressed: bool):
		seed_spin.editable = not pressed
		seed_spin.modulate = Color(0.7, 0.7, 0.7) if pressed else Color(1, 1, 1)
	)

	random_seed_check.button_pressed = (game_seed < 0)
	seed_spin.editable = not random_seed_check.button_pressed
	seed_spin.modulate = Color(0.7, 0.7, 0.7) if random_seed_check.button_pressed else Color(1, 1, 1)
	refresh_player_preview.call(player_count)

func _refresh_settings_summary() -> void:
	if _settings_summary == null:
		return
	var seed_text = "Random" if game_seed < 0 else str(game_seed)
	_settings_summary.text = "Players: %s  |  Seed: %s" % [player_count, seed_text]
