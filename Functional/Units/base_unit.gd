extends StaticBody3D
class_name BaseUnit

# -------- ENUMS --------
enum BuildFace {
	TOP    = 1 << 0,
	BOTTOM = 1 << 1,
	NORTH  = 1 << 2,
	SOUTH  = 1 << 3,
	EAST   = 1 << 4,
	WEST   = 1 << 5
}

# -------- CONFIG --------
@export var unit_type: String = "BaseUnit"
@export var size: Vector3 = Vector3.ONE

@export_flags("TOP", "BOTTOM", "NORTH", "SOUTH", "EAST", "WEST")
var build_faces: int = (
	BuildFace.TOP |
	BuildFace.NORTH |
	BuildFace.SOUTH |
	BuildFace.EAST |
	BuildFace.WEST
)

@export var inv_size: int = 5
@export var process_interval: float = 1.0

# -------- STATE --------
# Inventory: slot -> { "item_type": String, "amount": int }
var inventory: Dictionary[int, Dictionary] = {}

# Neighbors: BuildFace -> BaseUnit
var neighbors: Dictionary[int, BaseUnit] = {}

var _process_timer: float = 0.0

# -------- READY --------
func _ready() -> void:
	for i in range(inv_size):
		inventory[i] = {}

# -------- BUILDFACE LOGIC --------
func can_build_on(normal: Vector3) -> bool:
	var face: int = normal_to_face(normal)
	return (build_faces & face) != 0

func normal_to_face(n: Vector3) -> int:
	var abs_n := Vector3(abs(n.x), abs(n.y), abs(n.z))

	if abs_n.x > abs_n.y and abs_n.x > abs_n.z:
		return BuildFace.EAST if n.x > 0 else BuildFace.WEST
	elif abs_n.y > abs_n.x and abs_n.y > abs_n.z:
		return BuildFace.TOP if n.y > 0 else BuildFace.BOTTOM
	else:
		return BuildFace.SOUTH if n.z > 0 else BuildFace.NORTH

# -------- PROCESS TIMER --------
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_process_timer += delta
	if _process_timer >= process_interval:
		_process_timer = 0.0
		process_tick()

func process_tick() -> void:
	# Override in children for automation / processing
	pass

# -------- INVENTORY IO --------
func try_input(slot: int, item_type: String, amount: int) -> int:
	if slot < 0 or slot >= inv_size:
		return 0

	var slot_data: Dictionary = inventory[slot]

	if slot_data.is_empty():
		inventory[slot] = {"item_type": item_type, "amount": amount}
		return amount

	if slot_data.get("item_type", "") == item_type:
		slot_data["amount"] += amount
		return amount

	return 0

func try_output(slot: int, amount: int) -> int:
	if slot < 0 or slot >= inv_size:
		return 0

	var slot_data: Dictionary = inventory[slot]
	if slot_data.is_empty():
		return 0

	var give: int = min(slot_data["amount"], amount)
	slot_data["amount"] -= give

	if slot_data["amount"] <= 0:
		inventory[slot] = {}

	return give
