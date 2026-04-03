@icon("res://addons/movement_system/movement_system/icons/Movement_Manager.svg")
class_name MovementManager
extends Node

@export var controller: CharacterBody3D
@export var camera: Camera3D
@export var input_context : GUIDEMappingContext

var extensions: Array[MovementExtension] = []
var mode_manager: MovementModeManager
var additive_extensions: Array[MovementExtension] = []
var subtractive_extensions: Array[MovementExtension] = []
var overriding_extensions: Array[MovementExtension] = []
var constant_extensions: Array[MovementExtension] = []

var is_grounded : bool
signal on_grounded_change(bool)
signal on_start_grounded
signal on_start_in_air
#var current_velocity : Vector3 

func _ready() -> void:
	GUIDE.enable_mapping_context(input_context)
	
	_ensure_controller_and_camera_are_assigned()

	extensions.clear()
	additive_extensions.clear()
	subtractive_extensions.clear()
	overriding_extensions.clear()
	constant_extensions.clear()

	for child in get_children():
		if child is MovementExtension:
			extensions.append(child)
		if child is MovementModeManager and mode_manager == null:
			mode_manager = child as MovementModeManager
	
	for extension in extensions:
		extension.manager = self
		match extension.blend_mode:
			MovementExtension.ExtensionBlendMode.ADDITIVE:
				additive_extensions.append(extension)
			MovementExtension.ExtensionBlendMode.SUBTRACTIVE:
				subtractive_extensions.append(extension)
			MovementExtension.ExtensionBlendMode.OVERRIDING:
				overriding_extensions.append(extension)
			MovementExtension.ExtensionBlendMode.CONSTANT:
				constant_extensions.append(extension)

	_sort_extensions_by_execution_priority()

	call_deferred("_validate_configuration")

func _physics_process(delta: float) -> void:
	if controller == null:
		_ensure_controller_and_camera_are_assigned()
		if controller == null:
			return

	if mode_manager != null:
		mode_manager.refresh_and_apply_modes(delta)
	
	_on_grounded_check()
	
	var resolved_velocity := _resolve_movement_velocity(delta)
	controller.velocity = resolved_velocity
	controller.move_and_slide()
	#current_velocity = controller.velocity

	controller.rotation = _resolve_rotation_euler(delta)

func _ensure_controller_and_camera_are_assigned() -> void:
	if controller == null and get_parent() is CharacterBody3D:
		controller = get_parent() as CharacterBody3D

	if camera == null:
		camera = get_viewport().get_camera_3d()

func _update_extension_states(delta: float) -> void:
	for extension in extensions:
		extension.pre_update_extension_state(delta)

	for extension in extensions:
		extension.update_extension_state(delta)

	for extension in extensions:
		extension.post_update_extension_state(delta)

func _resolve_movement_velocity( delta: float) -> Vector3:
	var constant_velocity: Vector3 = Vector3.ZERO
	for extension in constant_extensions:
		if extension.is_active:
			constant_velocity += extension.get_movement_velocity(delta)

	for extension in overriding_extensions:
		if extension.is_active:
			return constant_velocity + extension.get_movement_velocity(delta)

	var blended_velocity: Vector3 = Vector3.ZERO
	for extension in additive_extensions:
		if extension.is_active:
			blended_velocity += extension.get_movement_velocity(delta)

	for extension in subtractive_extensions:
		if extension.is_active:
			blended_velocity -= extension.get_movement_velocity(delta)

	return constant_velocity + blended_velocity

func _resolve_rotation_euler(delta: float) -> Vector3:
	var constant_rotation: Vector3 = Vector3.ZERO
	for extension in constant_extensions:
		if extension.is_active:
			constant_rotation += extension.get_rotation_euler(delta)

	for extension in overriding_extensions:
		if extension.is_active:
			return constant_rotation + extension.get_rotation_euler(delta)

	var blended_rotation: Vector3 = Vector3.ZERO
	for extension in additive_extensions:
		if extension.is_active:
			blended_rotation += extension.get_rotation_euler(delta)

	for extension in subtractive_extensions:
		if extension.is_active:
			blended_rotation -= extension.get_rotation_euler(delta)

	return constant_rotation + blended_rotation

func _on_grounded_check() -> void:
	if is_grounded != controller.is_on_floor():
		if controller.is_on_floor():
			is_grounded = true
			on_start_grounded.emit()
		else:
			is_grounded = false
			on_start_in_air.emit()
		on_grounded_change.emit()

func get_extension_by_blend_mode(blend_mode : MovementExtension.ExtensionBlendMode) -> Array[MovementExtension]:
	match blend_mode:
		MovementExtension.ExtensionBlendMode.ADDITIVE:
			return additive_extensions
		MovementExtension.ExtensionBlendMode.SUBTRACTIVE:
			return subtractive_extensions
		MovementExtension.ExtensionBlendMode.OVERRIDING:
			return overriding_extensions
		MovementExtension.ExtensionBlendMode.CONSTANT:
			return constant_extensions
	return []

func get_camera_relative_input(input_vector: Vector3) -> Vector3:
	var active_camera := camera if camera != null else get_viewport().get_camera_3d()
	if active_camera == null:
		return input_vector

	var character_up := controller.up_direction if controller != null else Vector3.UP

	var camera_forward := (-active_camera.global_basis.z).slide(character_up)
	if camera_forward.length_squared() > 0.0:
		camera_forward = camera_forward.normalized()
	else:
		camera_forward = -active_camera.global_basis.z.normalized()

	var camera_right := active_camera.global_basis.x.slide(character_up)
	if camera_right.length_squared() > 0.0:
		camera_right = camera_right.normalized()
	else:
		camera_right = active_camera.global_basis.x.normalized()

	return (camera_right * input_vector.x) + (camera_forward * -input_vector.z) + (character_up * input_vector.y)

func get_character_relative_input(input_vector: Vector3) -> Vector3:
	if controller == null:
		return input_vector

	var character_up := controller.up_direction

	var character_forward := (-controller.global_basis.z).slide(character_up)
	if character_forward.length_squared() > 0.0:
		character_forward = character_forward.normalized()
	else:
		character_forward = -controller.global_basis.z.normalized()

	var character_right := controller.global_basis.x.slide(character_up)
	if character_right.length_squared() > 0.0:
		character_right = character_right.normalized()
	else:
		character_right = controller.global_basis.x.normalized()

	return (character_right * input_vector.x) + (character_forward * -input_vector.z) + (character_up * input_vector.y)

func get_world_vector_in_character_space(world_vector: Vector3) -> Vector3:
	if controller == null:
		return world_vector

	var local_vector := controller.global_basis.inverse() * world_vector
	# Keep the same sign convention as input vectors: forward is negative Z input.
	return Vector3(local_vector.x, local_vector.y, local_vector.z)

func _sort_extensions_by_execution_priority() -> void:
	var compare_callable: Callable = Callable(self, "_compare_extension_execution_order")
	extensions.sort_custom(compare_callable)
	additive_extensions.sort_custom(compare_callable)
	subtractive_extensions.sort_custom(compare_callable)
	overriding_extensions.sort_custom(compare_callable)
	constant_extensions.sort_custom(compare_callable)

func _compare_extension_execution_order(first_extension: MovementExtension, second_extension: MovementExtension) -> bool:
	if first_extension.execution_priority != second_extension.execution_priority:
		return first_extension.execution_priority < second_extension.execution_priority

	var first_path: String = String(get_path_to(first_extension))
	var second_path: String = String(get_path_to(second_extension))
	return first_path < second_path
