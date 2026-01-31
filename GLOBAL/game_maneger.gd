extends Node

enum CameraMode {
	MOVE_XZ,
	MOVE_Y,
	ROTATE
}

enum GameState {
	EDIT_MODE,
	SIMULATE_MODE
}

var peak: int 

@onready var test_block: PackedScene = preload("res://test/test_block.tscn")

func _ready() -> void:
	SignalManeger.mouse_interact.connect(_on_mouse)

func _on_mouse(hit: Dictionary, button: int) -> void:
	if button != MOUSE_BUTTON_LEFT:
		return
	if hit.collider is not BaseUnit:
		return

	var target: BaseUnit = hit.collider

	# check if this face allows building
	if not target.can_build_on(hit.normal):
		return

	# get the build face enum
	var face: int = target.normal_to_face(hit.normal)
	
	# instantiate new block
	var new_unit: BaseUnit = test_block.instantiate()
	new_unit.name = "test"

	# calculate snap offset
	var snap_offset: Vector3 = target.get_snap_offset(face, new_unit.size)

	# add to scene first
	get_tree().current_scene.add_child(new_unit)

	# set position relative to target
	new_unit.global_transform.origin = target.global_transform.origin + snap_offset
	
	# update neighbors after it's in the tree
	new_unit.update_neighbors()

