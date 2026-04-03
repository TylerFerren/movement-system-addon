@tool
extends EditorPlugin

const TYPES := [
	{
		"name": "MovementManager",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/movement_manager.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Movement_Manager.svg"
	},
	{
		"name": "MovementModeManager",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/movement_modes/movement_mode_manager.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Mode Manager.png"
	},
	{
		"name": "MovementMode",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/movement_modes/movement_mode.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Mode.png"
	},
	{
		"name": "Locomotion",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/extensions/locomotion_extension.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Locomotion.svg"
	},
	{
		"name": "Rotation",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/extensions/rotation_extension.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Rotation.svg"
	},
	{
		"name": "Jump",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/extensions/jump_extension.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Jump.svg"
	},
	{
		"name": "Gravity",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/extensions/gravity_extension.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Gravity.svg"
	},
	{
		"name": "Stance",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/extensions/stance_extension.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Stance.svg"
	},
	{
		"name": "LocomotionExtensionOverride",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/extensions/setting_overrides/locomotion_extension_override.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Locomotion Settings.svg"
	},
	{
		"name": "RotationExtensionOverride",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/extensions/setting_overrides/rotation_extension_override.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Rotation Settings.svg"
	},
	{
		"name": "JumpExtensionOverride",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/extensions/setting_overrides/jump_extension_override.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Jump Settings.svg"
	},
	{
		"name": "GravityExtensionOverride",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/extensions/setting_overrides/gravity_extension_override.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Gravity Settings.svg"
	},
	{
		"name": "StanceExtensionOverride",
		"base": "Node",
		"script": "res://addons/movement_system/movement_system/extensions/setting_overrides/stance_extension_override.gd",
		"icon": "res://addons/movement_system/movement_system/icons/Stance Settings.svg"
	},
]

var _registered_types: Array[String] = []

func _enter_tree() -> void:
	for type_def in TYPES:
		var script := load(type_def["script"]) as Script
		var icon := load(type_def["icon"]) as Texture2D
		if script == null:
			push_warning("Movement System plugin: failed to load script %s" % type_def["script"])
			continue
		add_custom_type(type_def["name"], type_def["base"], script, icon)
		_registered_types.append(type_def["name"])

func _exit_tree() -> void:
	for i in range(_registered_types.size() - 1, -1, -1):
		remove_custom_type(_registered_types[i])
	_registered_types.clear()
