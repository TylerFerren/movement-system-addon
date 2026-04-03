@icon("res://movement_system/icons/Jump Settings.svg")
class_name JumpExtensionOverride
extends ExtensionSettingOverride

@export var override_jump_height: bool = false
@export var jump_height: float = 3.0

@export var override_air_jumps: bool = false
@export var air_jumps: int = 1

@export var override_fast_fall_multiplier: bool = false
@export var fast_fall_multiplier: float = 2.0

@export var override_low_jump_multiplier: bool = false
@export var low_jump_multiplier: float = 2.0

@export var override_coyote_time: bool = false
@export var coyote_time: float = 0.2

func supports_extension(target_extension: MovementExtension) -> bool:
	return target_extension is Jump

func get_overridden_property_names() -> PackedStringArray:
	return PackedStringArray([
		"jump_height",
		"air_jumps",
		"fast_fall_multiplier",
		"low_jump_multiplier",
		"coyote_time"
	])

func apply_to_extension(target_extension: MovementExtension) -> void:
	var jump_extension := target_extension as Jump
	if jump_extension == null:
		return

	if override_jump_height:
		jump_extension.jump_height = jump_height
	if override_air_jumps:
		jump_extension.air_jumps = air_jumps
	if override_fast_fall_multiplier:
		jump_extension.fast_fall_multiplier = fast_fall_multiplier
	if override_low_jump_multiplier:
		jump_extension.low_jump_multiplier = low_jump_multiplier
	if override_coyote_time:
		jump_extension.coyote_time = coyote_time
