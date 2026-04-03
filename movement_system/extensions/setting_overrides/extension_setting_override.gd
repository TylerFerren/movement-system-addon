@abstract
class_name ExtensionSettingOverride
extends Node

@export var enabled: bool = true
@export_group("Activation")
@export var extension_should_be_active: bool = true

func can_apply() -> bool:
	return enabled

@abstract
func supports_extension(_target_extension: MovementExtension) -> bool

@abstract
func get_overridden_property_names() -> PackedStringArray

@abstract
func apply_to_extension(_target_extension: MovementExtension) -> void
