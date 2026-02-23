extends RefCounted

var CONTRACTS: Array[Dictionary] = [
	{
		"scene": "res://ui/MainMenu.tscn",
		"nodes": PackedStringArray([
			"StatusBanner",
			"CenterContainer/MenuCard/MarginContainer/VBoxContainer/SettingsSummary",
			"CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/StartButton",
			"CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/SettingsButton",
			"CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/QuitButton",
		]),
	},
	{
		"scene": "res://ui/OnlineLobby.tscn",
		"nodes": PackedStringArray([
			"Margin/RootCard/CardMargin/VBox/Buttons/LoginBtn",
			"Margin/RootCard/CardMargin/VBox/Buttons/QuickBtn",
			"Margin/RootCard/CardMargin/VBox/Buttons/PrivateBtn",
			"Margin/RootCard/CardMargin/VBox/Buttons/ReadyBtn",
			"Margin/RootCard/CardMargin/VBox/Buttons/StartBtn",
			"Margin/RootCard/CardMargin/VBox/Buttons/BackBtn",
			"Margin/RootCard/CardMargin/VBox/PromptStrip",
			"Margin/RootCard/CardMargin/VBox/EmoteRow/EmoteButtons",
		]),
	},
	{
		"scene": "res://ui/SettingsMenu.tscn",
		"nodes": PackedStringArray([
			"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/InitialOpenPoints/Value",
			"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/AllowFivePairsOpen/Value",
			"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/TurnTimer/Value",
			"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/MatchEndCondition/Value",
			"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/MatchEndValue/Value",
			"Panel/MarginContainer/VBoxContainer/ButtonContainer/SaveButton",
			"Panel/MarginContainer/VBoxContainer/ButtonContainer/CancelButton",
			"Panel/MarginContainer/VBoxContainer/PromptStrip",
		]),
	},
]


func run() -> bool:
	var ok: bool = true
	for contract in CONTRACTS:
		if not _validate_scene(contract):
			ok = false
	return ok


func _validate_scene(contract: Dictionary) -> bool:
	var scene_path: String = String(contract.get("scene", ""))
	var required_nodes: PackedStringArray = contract.get("nodes", PackedStringArray())

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Failed to load scene: %s" % scene_path)
		return false

	var root: Node = packed.instantiate()
	if root == null:
		push_error("Failed to instantiate scene: %s" % scene_path)
		return false

	for node_path in required_nodes:
		if root.get_node_or_null(node_path) == null:
			push_error("Missing required node in %s: %s" % [scene_path, node_path])
			root.free()
			return false

	root.free()
	return true
