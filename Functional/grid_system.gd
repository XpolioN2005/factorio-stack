extends Node3D

var spatial: Dictionary[Vector3i, BaseUnit] = {}
@export var CELL_SIZE: float = 1.0

# -------- UTILS --------

const FACE_TO_CELL: Dictionary = {
	BaseUnit.BuildFace.TOP:    Vector3i(0, 1, 0),
	BaseUnit.BuildFace.BOTTOM: Vector3i(0, -1, 0),
	BaseUnit.BuildFace.NORTH:  Vector3i(0, 0, -1),
	BaseUnit.BuildFace.SOUTH:  Vector3i(0, 0, 1),
	BaseUnit.BuildFace.EAST:   Vector3i(1, 0, 0),
	BaseUnit.BuildFace.WEST:   Vector3i(-1, 0, 0),
}

const OPPOSITE_FACE: Dictionary = {
	BaseUnit.BuildFace.TOP:    BaseUnit.BuildFace.BOTTOM,
	BaseUnit.BuildFace.BOTTOM: BaseUnit.BuildFace.TOP,
	BaseUnit.BuildFace.NORTH:  BaseUnit.BuildFace.SOUTH,
	BaseUnit.BuildFace.SOUTH:  BaseUnit.BuildFace.NORTH,
	BaseUnit.BuildFace.EAST:   BaseUnit.BuildFace.WEST,
	BaseUnit.BuildFace.WEST:   BaseUnit.BuildFace.EAST,
}

func world_to_cell(pos: Vector3) -> Vector3i:
	return Vector3i(
		round(pos.x / CELL_SIZE),
		round(pos.y / CELL_SIZE),
		round(pos.z / CELL_SIZE)
	)

# -------- PLACEMENT --------
func place_unit(unit_scene: PackedScene, target: BaseUnit, hit_normal: Vector3) -> void:
	if not target.can_build_on(hit_normal):
		return

	var face: int = target.normal_to_face(hit_normal)
	var dir: Vector3i = FACE_TO_CELL[face]

	var target_cell: Vector3i = world_to_cell(target.global_transform.origin)
	var new_cell: Vector3i = target_cell + dir

	if spatial.has(new_cell):
		return

	var new_unit: BaseUnit = unit_scene.instantiate()
	add_child(new_unit)

	new_unit.name = "%s-%s" % [new_unit.unit_type, new_cell]
	new_unit.global_transform.origin = Vector3(new_cell) * CELL_SIZE

	spatial[new_cell] = new_unit

	if GameManeger.peak < new_cell.y:
		GameManeger.peak = new_cell.y

	# Link main neighbors
	target.neighbors[face] = new_unit
	new_unit.neighbors[OPPOSITE_FACE[face]] = target

	# Link side neighbors
	for f in FACE_TO_CELL.keys():
		var c: Vector3i = new_cell + FACE_TO_CELL[f]
		if spatial.has(c):
			var n: BaseUnit = spatial[c]
			new_unit.neighbors[f] = n
			n.neighbors[OPPOSITE_FACE[f]] = new_unit

# -------- REMOVAL --------
func remove_unit(target: BaseUnit) -> void:
	var cell: Vector3i = world_to_cell(target.global_transform.origin)

	for face in target.neighbors.keys():
		var n: BaseUnit = target.neighbors[face]
		if is_instance_valid(n):
			n.neighbors.erase(OPPOSITE_FACE[face])

	target.neighbors.clear()
	spatial.erase(cell)
	target.queue_free()

# -------- TEST --------
@onready var test_block: PackedScene = preload("res://test/test_block.tscn")

func _ready() -> void:
	SignalManeger.mouse_interact.connect(_on_mouse)

func _on_mouse(hit: Dictionary, button: int) -> void:
	if hit.collider is not BaseUnit:
		return

	var target: BaseUnit = hit.collider

	if button == MOUSE_BUTTON_LEFT:
		place_unit(test_block, target, hit.normal)
	elif button == MOUSE_BUTTON_RIGHT:
		remove_unit(target)
