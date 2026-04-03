@icon("res://addons/movement_system/movement_system/icons/Stance.svg")
class_name Stance
extends MovementExtension

@export_group("Height")
@export var target_height: float = 2.0

@export_group("Transition")
@export var transition_speed: float = 12.0

var _collision_shape: CollisionShape3D
var _capsule_shape: CapsuleShape3D
var _baseline_bottom_y: float = 0.0

func _ready() -> void:
	_resolve_capsule_collision_shape()
	_capture_baseline()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	if _capsule_shape == null:
		_resolve_capsule_collision_shape()
		_capture_baseline()
		if _capsule_shape == null:
			return

	var desired_height := _get_clamped_target_height()
	var t := clampf(transition_speed * delta, 0.0, 1.0)
	var new_height := lerpf(_capsule_shape.height, desired_height, t)
	_apply_capsule_height(new_height)

func _resolve_capsule_collision_shape() -> void:
	_collision_shape = null
	_capsule_shape = null
	if manager == null or manager.controller == null:
		return

	_collision_shape = _find_first_capsule_collision_shape(manager.controller)
	if _collision_shape == null:
		return

	_capsule_shape = _collision_shape.shape as CapsuleShape3D

func _find_first_capsule_collision_shape(root: Node) -> CollisionShape3D:
	if root is CollisionShape3D:
		var direct_shape := (root as CollisionShape3D).shape
		if direct_shape is CapsuleShape3D:
			return root as CollisionShape3D

	for child in root.get_children():
		var found := _find_first_capsule_collision_shape(child)
		if found != null:
			return found

	return null

func _capture_baseline() -> void:
	if _collision_shape == null or _capsule_shape == null:
		return

	_baseline_bottom_y = _collision_shape.position.y - (_capsule_shape.height * 0.5)
	if target_height <= 0.0:
		target_height = _capsule_shape.height

func _get_clamped_target_height() -> float:
	# Capsule height cannot go below diameter.
	var min_height := _capsule_shape.radius * 2.0
	return maxf(target_height, min_height)

func _apply_capsule_height(new_height: float) -> void:
	_capsule_shape.height = new_height
	# Keep capsule feet anchored while changing height.
	_collision_shape.position.y = _baseline_bottom_y + (new_height * 0.5)
