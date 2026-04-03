@icon("res://addons/movement_system/movement_system/icons/Mode Manager.png")
class_name MovementModeManager
extends Node

# Child node name used as an override container inside each mode.
const OVERRIDES_CONTAINER_NAME := "extension_override_settings"

var movement_manager: MovementManager
var _baseline_extension_state: Dictionary = {}
var _has_captured_baseline: bool = false
var _active_mode_chain: Array[MovementMode] = []
@export_group("Debug")
@export var debug_print_active_modes: bool = false
var _last_debug_chain_key: String = ""

func _ready() -> void:
	movement_manager = _resolve_movement_manager()

func activate_mode_by_name(mode_name: StringName) -> void:
	set_mode_active_by_name(mode_name, true)

func deactivate_mode_by_name(mode_name: StringName) -> void:
	set_mode_active_by_name(mode_name, false)

func set_mode_active_by_name(mode_name: StringName, active: bool) -> void:
	var target_mode := _find_mode_by_name(self, mode_name)
	if target_mode == null:
		push_warning("MovementModeManager: mode '%s' was not found." % String(mode_name))
		return
	_set_mode_active(target_mode, active)

func _find_mode_by_name(parent_node: Node, mode_name: StringName) -> MovementMode:
	for child in parent_node.get_children():
		var mode := child as MovementMode
		if mode == null:
			continue
		if mode.get_mode_name() == mode_name:
			return mode
		var nested := _find_mode_by_name(mode, mode_name)
		if nested != null:
			return nested
	return null

func _set_mode_active(mode: MovementMode, active: bool) -> void:
	if not active:
		mode.set_active(false)
		_set_descendant_modes_active(mode, false)
		return

	# Ensure all parents in the mode chain are active and exclusive among siblings.
	var current := mode
	while current != null and current != self:
		var current_mode := current as MovementMode
		if current_mode != null:
			_set_sibling_modes_active(current_mode, false)
			current_mode.set_active(true)
		current = current.get_parent()

func _set_sibling_modes_active(mode: MovementMode, active: bool) -> void:
	var parent_node := mode.get_parent()
	if parent_node == null:
		return

	for child in parent_node.get_children():
		var sibling := child as MovementMode
		if sibling == null:
			continue
		if sibling == mode:
			continue
		sibling.set_active(active)
		if not active:
			_set_descendant_modes_active(sibling, false)

func _set_descendant_modes_active(parent_mode: MovementMode, active: bool) -> void:
	for child in parent_mode.get_children():
		var child_mode := child as MovementMode
		if child_mode == null:
			continue
		child_mode.set_active(active)
		_set_descendant_modes_active(child_mode, active)

func _resolve_movement_manager() -> MovementManager:
	var current := get_parent()
	while current != null:
		if current is MovementManager:
			return current as MovementManager
		current = current.get_parent()
	return null

func refresh_and_apply_modes(delta: float = 0.0) -> void:
	if movement_manager == null:
		movement_manager = _resolve_movement_manager()
	if movement_manager == null:
		return

	_ensure_baseline_is_captured()
	var new_active_mode_chain := _resolve_active_mode_chain(self)
	_dispatch_mode_transitions(new_active_mode_chain)
	_active_mode_chain = new_active_mode_chain
	_debug_print_active_chain_if_changed()
	_dispatch_mode_tick(delta)
	# Start each resolve pass from extension defaults before applying active modes.
	_reset_extensions_for_mode_pass()
	_apply_mode_chain_overrides()

func _reset_extensions_for_mode_pass() -> void:
	if movement_manager == null:
		return
	if not _has_captured_baseline:
		return
	_restore_baseline_extension_state()

func _apply_mode_chain_overrides() -> void:
	# Parent applies first, then child layers on top and wins conflicts.
	for mode in _active_mode_chain:
		_apply_mode_overrides(mode)

func _get_first_active_child_mode(parent_node: Node) -> MovementMode:
	for child in parent_node.get_children():
		var mode := child as MovementMode
		if mode == null:
			continue
		if mode.active:
			return mode
	return null

func _resolve_active_mode_chain(parent_node: Node) -> Array[MovementMode]:
	var resolved_chain: Array[MovementMode] = []
	var current_parent := parent_node
	while true:
		var active_mode := _get_first_active_child_mode(current_parent)
		if active_mode == null:
			break
		resolved_chain.append(active_mode)
		current_parent = active_mode
	return resolved_chain

func get_active_mode_names() -> PackedStringArray:
	var names := PackedStringArray()
	for mode in _active_mode_chain:
		names.append(String(mode.get_mode_name()))
	return names

func _debug_print_active_chain_if_changed() -> void:
	if not debug_print_active_modes:
		return

	var names := get_active_mode_names()
	var chain_key := " > ".join(names)
	if chain_key == _last_debug_chain_key:
		return
	_last_debug_chain_key = chain_key

	if chain_key.is_empty():
		print("[MovementModeManager] Active Modes: <none>")
		return
	print("[MovementModeManager] Active Modes: %s" % chain_key)

func _dispatch_mode_transitions(new_active_mode_chain: Array[MovementMode]) -> void:
	var shared_prefix_size: int = 0
	while shared_prefix_size < _active_mode_chain.size() and shared_prefix_size < new_active_mode_chain.size():
		if _active_mode_chain[shared_prefix_size] != new_active_mode_chain[shared_prefix_size]:
			break
		shared_prefix_size += 1

	# Exit deepest modes first.
	for index in range(_active_mode_chain.size() - 1, shared_prefix_size - 1, -1):
		_active_mode_chain[index].on_exit_mode(movement_manager)

	# Enter from parent to child.
	for index in range(shared_prefix_size, new_active_mode_chain.size()):
		new_active_mode_chain[index].on_enter_mode(movement_manager)

func _dispatch_mode_tick(delta: float) -> void:
	for mode in _active_mode_chain:
		mode.on_mode_tick(movement_manager, delta)

func _ensure_baseline_is_captured() -> void:
	if _has_captured_baseline:
		return
	_capture_baseline_extension_state()

func _capture_baseline_extension_state() -> void:
	_baseline_extension_state.clear()
	if movement_manager == null:
		return

	for extension in movement_manager.extensions:
		var entry := {
			"is_active": extension.is_active,
			"properties": {}
		}

		var property_names := _collect_override_property_names_for_extension(extension)
		for property_name in property_names:
			if not _node_has_property(extension, property_name):
				continue
			entry["properties"][property_name] = extension.get(property_name)

		_baseline_extension_state[extension] = entry

	_has_captured_baseline = true

func _restore_baseline_extension_state() -> void:
	if movement_manager == null:
		return

	for extension in movement_manager.extensions:
		var entry: Dictionary = _baseline_extension_state.get(extension, {})
		if entry.is_empty():
			continue

		var properties: Dictionary = entry.get("properties", {})
		for property_name in properties.keys():
			if _node_has_property(extension, property_name):
				extension.set(property_name, properties[property_name])

		if entry.has("is_active"):
			extension.set_active(entry["is_active"])

func _collect_override_property_names_for_extension(extension: MovementExtension) -> PackedStringArray:
	var property_name_set := {}
	for mode in _collect_all_modes(self):
		var overrides_container := _get_overrides_container(mode)
		for child in overrides_container.get_children():
			var setting_override := child as ExtensionSettingOverride
			if setting_override == null:
				continue
			if not setting_override.supports_extension(extension):
				continue
			for property_name in setting_override.get_overridden_property_names():
				property_name_set[property_name] = true

	var names: PackedStringArray = PackedStringArray()
	for property_name in property_name_set.keys():
		names.append(property_name)
	return names

func _collect_all_modes(parent_node: Node) -> Array[MovementMode]:
	var found_modes: Array[MovementMode] = []
	for child in parent_node.get_children():
		var mode := child as MovementMode
		if mode == null:
			continue
		found_modes.append(mode)
		found_modes.append_array(_collect_all_modes(mode))
	return found_modes

func _node_has_property(node: Object, property_name: StringName) -> bool:
	for property_info in node.get_property_list():
		if property_info.get("name") == property_name:
			return true
	return false

func _apply_mode_overrides(mode: MovementMode) -> void:
	var overrides_container := _get_overrides_container(mode)
	for child in overrides_container.get_children():
		var setting_override := child as ExtensionSettingOverride
		if setting_override == null:
			continue
		if not setting_override.can_apply():
			continue

		for extension in movement_manager.extensions:
			if not setting_override.supports_extension(extension):
				continue
			extension.set_active(setting_override.extension_should_be_active)
			setting_override.apply_to_extension(extension)

func _get_overrides_container(mode: MovementMode) -> Node:
	var container := mode.get_node_or_null(OVERRIDES_CONTAINER_NAME)
	if container != null:
		return container
	return mode
