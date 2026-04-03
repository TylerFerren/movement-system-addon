@abstract
class_name MovementExtension
extends Node

enum ExtensionBlendMode {ADDITIVE, SUBTRACTIVE, OVERRIDING, CONSTANT}

var manager : MovementManager
@export var blend_mode : ExtensionBlendMode = ExtensionBlendMode.ADDITIVE

@export var execution_priority: int = 0

var is_active : bool = true

func set_active(value: bool) -> void:
	is_active = value

func get_movement_velocity(_delta: float) -> Vector3:
	return Vector3.ZERO

func get_rotation_euler(_delta: float) -> Vector3:
	return Vector3.ZERO
