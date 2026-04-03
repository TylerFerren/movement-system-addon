@icon("res://addons/movement_system/movement_system/icons/Locomotion.svg")
class_name Locomotion
extends MovementExtension

@export var speed: float = 5.0
@export var acceleration: float = 3.0
@export var deceleration: float = 5.0
@export var directional_acceleration: float = 4.0


var target_direction: Vector3 = Vector3.ZERO
var smoothed_direction: Vector3 = Vector3.ZERO
var target_speed: float = 0.0
var smoothed_speed: float = 0.0

var move_input : Vector2 = Vector2(0,0)

func on_move_input(vector : Vector2) -> void:
	move_input = vector

func get_movement_velocity(delta: float) -> Vector3:
	var move_input_direction := Vector3(move_input.x, 0.0, move_input.y)
	var camera_relative_input := manager.get_camera_relative_input(move_input_direction)
	var floor_plane_direction : Vector3 = camera_relative_input
	if manager.controller.is_on_floor():
		floor_plane_direction = camera_relative_input.slide(manager.controller.get_floor_normal())
	if floor_plane_direction.length_squared() > 0.0:
		target_direction = floor_plane_direction.normalized()
	else:
		target_direction = Vector3.ZERO

	smoothed_direction = lerp(smoothed_direction, target_direction, directional_acceleration * delta).normalized()
	
	target_speed = speed * move_input.normalized().length()
	if target_speed > 0.0:
		smoothed_speed = lerp(smoothed_speed, target_speed, acceleration * delta)
	else:
		smoothed_speed = lerp(smoothed_speed, target_speed, deceleration * delta)
	
	return smoothed_speed * smoothed_direction
