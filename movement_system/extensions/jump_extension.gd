@icon("res://movement_system/icons/Jump.svg")
class_name Jump
extends MovementExtension

@export var jump_height: float = 3.0
@export var air_jumps: int = 1
@export var fast_fall_multiplier: float = 2.0
@export var low_jump_multiplier: float = 2.0
@export var coyote_time: float = 0.2

signal jumped
signal jumped_in_air

var can_jump: bool = false
var jump_velocity: float = 0.0
var active_fast_fall_multiplier: float = 1.0
var active_low_jump_multiplier: float = 1.0
var coyote_timer: float = 0.0
var gravity_magnitude: float = 9.8
var current_air_jump_count: int = 0

var gravity_extension : Gravity

func _ready() -> void:
	if manager != null:
		for _extension in manager.get_children():
			if _extension is Gravity:
				gravity_extension = _extension
	gravity_magnitude = _get_gravity_magnitude()


func on_jump_pressed(value: bool) -> void:
	if value:
		print("jump called")
		_try_jump()
	else:
		_stop_jump()

func _try_jump() -> void:
	gravity_magnitude = _get_gravity_magnitude()
	
	if manager.controller.is_on_floor():
		current_air_jump_count = 0
	elif current_air_jump_count >= air_jumps:
		print(current_air_jump_count)
		return

	jump_velocity = sqrt(2.0 * jump_height * gravity_magnitude)

	# Offset falling speed so jump remains responsive while descending.
	if manager.controller.velocity.y < 0.0:
		manager.controller.velocity.y = 0

	active_fast_fall_multiplier = 1.0
	active_low_jump_multiplier = 1.0
	
	if manager.controller.is_on_floor():
		jumped.emit()
	else:
		current_air_jump_count += 1
		jumped_in_air.emit()

func _stop_jump() -> void:
	active_low_jump_multiplier = low_jump_multiplier

func get_movement_velocity(delta: float) -> Vector3:
	var movement_velocity: Vector3 = Vector3.ZERO

	if is_active:
		if manager.controller.velocity.y < 0.0 and is_equal_approx(active_fast_fall_multiplier, 1.0):
			active_fast_fall_multiplier = fast_fall_multiplier
			
		if jump_velocity > 0.0:
			jump_velocity -= active_fast_fall_multiplier * active_low_jump_multiplier * gravity_magnitude * delta

		jump_velocity = max(jump_velocity, 0.0)
		movement_velocity += manager.controller.up_direction * jump_velocity
	return movement_velocity

func _update_coyote_time(delta: float) -> void:
	if manager.controller.is_on_floor() and not is_active:
		coyote_timer = coyote_time
		can_jump = true
		return

	if can_jump:
		coyote_timer -= delta
		if coyote_timer <= 0.0:
			coyote_timer = 0.0
			can_jump = false

func _get_gravity_magnitude() -> float:
	if gravity_extension != null:
		return gravity_extension.gravity_force.length()
		
	return float(ProjectSettings.get_setting("physics/3d/default_gravity"))
