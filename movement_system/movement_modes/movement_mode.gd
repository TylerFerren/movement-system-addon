@icon("res://movement_system/icons/Mode.png")
class_name MovementMode
extends Node

# If true, this mode contributes its child overrides.
@export var active: bool = false

var overrides : Array[ExtensionSettingOverride]

signal on_enter
signal on_exit

func get_mode_name() -> StringName:
	# Use the node name as the single source of truth for mode identity.
	return StringName(name)

func set_active(value: bool) -> void:
	active = value

func get_mode_override_settings() -> void:
	for child in get_children():
		if child is ExtensionSettingOverride:
			overrides.append(child)

func on_enter_mode(_movement_manager: MovementManager) -> void:
	on_enter.emit()

func on_exit_mode(_movement_manager: MovementManager) -> void:
	on_exit.emit()

func on_mode_tick(_movement_manager: MovementManager, _delta: float) -> void:
	pass
