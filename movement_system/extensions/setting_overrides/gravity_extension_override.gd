@icon("res://movement_system/icons/Gravity Settings.svg")
class_name GravityExtensionOverride
extends ExtensionSettingOverride

@export var override_gravity_force: bool = false
@export var gravity_force: Vector3 = Vector3(0.0, -9.8, 0.0)

@export var override_minimum_fall_velocity: bool = false
@export var minimum_fall_velocity: float = -1.0

func supports_extension(target_extension: MovementExtension) -> bool:
	return target_extension is Gravity

func get_overridden_property_names() -> PackedStringArray:
	return PackedStringArray([
		"gravity_force",
		"minimum_fall_velocity"
	])

func apply_to_extension(target_extension: MovementExtension) -> void:
	var gravity_extension := target_extension as Gravity
	if gravity_extension == null:
		return

	if override_gravity_force:
		gravity_extension.gravity_force = gravity_force
	if override_minimum_fall_velocity:
		gravity_extension.minimum_fall_velocity = minimum_fall_velocity
