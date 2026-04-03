@icon("res://movement_system/icons/Rotation.svg")
class_name Rotation
extends MovementExtension

enum RotationDriver {MOVEMENT_DIRECTION, INPUT_DIRECTION, FOLLOW_CAMERA, CURSOR_BASED}

@export var rotation_driver : RotationDriver = RotationDriver.MOVEMENT_DIRECTION
@export_range(0 , 1440) var rotation_speed = 360
@export var only_rotate_on_move : bool = false
@export var lock_upright : bool = true

@export var cursor_ray_length : float = 1000.0
var input_vector : Vector2
@export var input_deadzone: float = 0.05
@export var direction_deadzone: float = 0.0001

var target_direction: Vector3 = Vector3.ZERO
var target_rotation: Vector3 = Vector3.ZERO
var smooth_rotation: Vector3 = Vector3.ZERO

func get_rotation_euler(delta: float) -> Vector3:
	match rotation_driver:
		RotationDriver.MOVEMENT_DIRECTION:
			_rotate_towards_movement()
		RotationDriver.INPUT_DIRECTION:
			_rotate_towards_input()
		RotationDriver.FOLLOW_CAMERA:
			_rotate_following_camera()
		RotationDriver.CURSOR_BASED:
			_rotate_towards_cursor()

	var has_rotation_direction: bool = target_direction.length_squared() > direction_deadzone
	if not has_rotation_direction:
		return smooth_rotation

	if only_rotate_on_move and manager.controller.velocity.length() <= input_deadzone:
		return smooth_rotation
	
	var horizontal_length := Vector2(target_direction.x, target_direction.z).length()
	var pitch_rotation := -atan2(target_direction.y, horizontal_length)
	var yaw_rotation := atan2(-target_direction.x, -target_direction.z)
	var roll_rotation := atan2(target_direction.x, horizontal_length)
	
	if lock_upright:
		target_rotation = Vector3(0.0, yaw_rotation, 0.0)
	else:
		target_rotation = Vector3(pitch_rotation, yaw_rotation, roll_rotation)
	
	var max_step := deg_to_rad(rotation_speed) * delta
	smooth_rotation = Vector3(
		move_toward(smooth_rotation.x, target_rotation.x, max_step),
		rotate_toward(smooth_rotation.y, target_rotation.y, max_step),
		move_toward(smooth_rotation.z, target_rotation.z, max_step)
	)
	return smooth_rotation

func _rotate_towards_movement() -> void:
	target_direction = manager.controller.velocity.slide(manager.controller.up_direction)
	if lock_upright:
		target_direction.y = 0.0
	if target_direction.length_squared() <= direction_deadzone:
		target_direction = Vector3.ZERO

func _rotate_towards_input() -> void:
	if input_vector.length() <= input_deadzone:
		target_direction = Vector3.ZERO
		return

	var input_direction := Vector3(input_vector.x, 0.0, input_vector.y)
	target_direction = manager.get_camera_relative_input(input_direction)
	if lock_upright:
		target_direction.y = 0.0
	if target_direction.length_squared() <= direction_deadzone:
		target_direction = Vector3.ZERO
	pass

func _rotate_following_camera() -> void:
	var active_camera := manager.camera
	if active_camera == null:
		target_direction = Vector3.ZERO
		return

	target_direction = -active_camera.global_basis.z
	if lock_upright:
		target_direction.y = 0.0
	if target_direction.length_squared() <= direction_deadzone:
		target_direction = Vector3.ZERO

func _rotate_towards_cursor() -> void:
	var active_camera := manager.camera
	if active_camera == null:
		target_direction = Vector3.ZERO
		return
	
	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := active_camera.project_ray_origin(mouse_position)
	var ray_direction := active_camera.project_ray_normal(mouse_position)
	var ray_end := ray_origin + (ray_direction * cursor_ray_length)
	
	var ray_query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	ray_query.exclude = [manager.controller.get_rid()]
	ray_query.collide_with_areas = true
	
	var world_space_state := manager.controller.get_world_3d().direct_space_state
	var raycast_hit := world_space_state.intersect_ray(ray_query)
	
	if raycast_hit.has("position"):
		target_direction = raycast_hit["position"] - manager.controller.global_position
	else:
		var ground_plane := Plane(Vector3.UP, manager.controller.global_position.y)
		var plane_hit_result: Variant = ground_plane.intersects_ray(ray_origin, ray_direction)
		if plane_hit_result == null:
			target_direction = Vector3.ZERO
			return
		var plane_hit_position: Vector3 = plane_hit_result
		target_direction = plane_hit_position - manager.controller.global_position

	if lock_upright:
		target_direction.y = 0.0
	if target_direction.length_squared() <= direction_deadzone:
		target_direction = Vector3.ZERO
