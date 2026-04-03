@icon("res://movement_system/icons/Stance Settings.svg")
class_name StanceExtensionOverride
extends ExtensionSettingOverride

@export var override_target_height: bool = false
@export var target_height: float = 2.0

@export var override_transition_speed: bool = false
@export var transition_speed: float = 12.0

func supports_extension(target_extension: MovementExtension) -> bool:
	return target_extension is Stance

func get_overridden_property_names() -> PackedStringArray:
	return PackedStringArray([
		"target_height",
		"transition_speed",
	])

func apply_to_extension(target_extension: MovementExtension) -> void:
	var stance_extension := target_extension as Stance
	if stance_extension == null:
		return

	if override_target_height:
		stance_extension.target_height = target_height
	if override_transition_speed:
		stance_extension.transition_speed = transition_speed
