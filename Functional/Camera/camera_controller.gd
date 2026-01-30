# camera_controller.gd
extends Node3D

#* Camera controller also handles input since the input is depended on camera anyways

# Root -> Anchore -> MainCamera
@onready var anchore: Node3D = $Anchore
@onready var mainCamera: Camera3D = $Anchore/MainCamera

# -------- CONFIG --------

@export_category("Behavior")
@export var is_locked: bool = false
@export var can_pan: bool = true
@export var can_rotate: bool = true
@export var can_zoom: bool = true

@export_category("Speed")
@export var pan_speed: float = 0.01
@export var rotate_speed: float = 0.01
@export var zoom_speed: float = 1.0

@export_category("Limits")
@export var min_pan_y: float = 0.0
@export var max_pan_y: float = 5.0
@export var min_pitch: float = -1.2
@export var max_pitch: float = -0.2
@export var min_zoom: float = 2.0
@export var max_zoom: float = 15.0

@export_category("Smooth")
@export var pan_smooth: float = 0.15
@export var rotate_smooth: float = 0.15
@export var zoom_smooth: float = 0.1

# -------- STATE --------

var camera_mode: GameManeger.CameraMode = GameManeger.CameraMode.MOVE_XZ

var target_pos: Vector3
var target_rot_x: float
var target_rot_y: float
var target_zoom: float

# Tap vs drag
var press_pos: Vector2 = Vector2.ZERO
var is_pressed: bool = false
var is_drag: bool = false
const DRAG_THRESHOLD: float = 10.0

# -------- SETUP --------

func _ready() -> void:
	target_pos = anchore.position
	target_rot_x = anchore.rotation.x
	target_rot_y = anchore.rotation.y
	target_zoom = mainCamera.position.z

	SignalManeger.request_camera_mode.connect(_on_request_camera_mode)


# -------- INPUT --------

func _unhandled_input(event: InputEvent) -> void:
	if is_locked:
		is_pressed = false
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		# Mouse wheel zoom
		if can_zoom and mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
				return
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)
				return

		_handle_button(mb)


	elif event is InputEventMouseMotion:
		_handle_motion(event as InputEventMouseMotion)

	elif can_zoom and event is InputEventMagnifyGesture:
		var mg: InputEventMagnifyGesture = event
		target_zoom = clamp(target_zoom - mg.factor * zoom_speed, min_zoom, max_zoom)

# -------- GESTURE --------

func _handle_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		press_pos = event.position
		is_pressed = true
		is_drag = false
	else:
		is_pressed = false
		if not is_drag:
			_fire_click(event)

func _handle_motion(event: InputEventMouseMotion) -> void:
	if not is_pressed:
		return

	var dist: float = press_pos.distance_to(event.position)
	if dist > DRAG_THRESHOLD:
		is_drag = true

	if is_drag:
		_apply_camera_drag(event.relative)

# -------- CLICK --------

func _fire_click(event: InputEventMouseButton) -> void:
	var hit: Dictionary = _raycast_from_camera(event.position)
	if hit.is_empty():
		return

	SignalManeger.mouse_interact.emit(hit, event.button_index)

# -------- CAMERA --------

func _on_request_camera_mode(mode: GameManeger.CameraMode) -> void:
	camera_mode = mode


func _apply_camera_drag(delta: Vector2) -> void:
	match camera_mode:
		GameManeger.CameraMode.MOVE_XZ:
			if not can_pan:
				return

			var right: Vector3 = anchore.global_transform.basis.x
			var forward: Vector3 = -anchore.global_transform.basis.z
			target_pos += (right * delta.x + forward * delta.y) * pan_speed

		GameManeger.CameraMode.MOVE_Y:
			if not can_pan:
				return

			target_pos.y -= delta.y * pan_speed
			target_pos.y = clamp(target_pos.y, min_pan_y, max_pan_y)

		GameManeger.CameraMode.ROTATE:
			if not can_rotate:
				return

			target_rot_y -= delta.x * rotate_speed
			target_rot_x -= delta.y * rotate_speed
			target_rot_x = clamp(target_rot_x, min_pitch, max_pitch)


# -------- RAYCAST --------

func _raycast_from_camera(mouse_pos: Vector2, max_distance: float = 1000.0, collision_mask: int = 0xFFFFFFFF) -> Dictionary:
	var ray_origin: Vector3 = mainCamera.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = mainCamera.project_ray_normal(mouse_pos)
	var ray_end: Vector3 = ray_origin + ray_dir * max_distance

	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = true

	return space.intersect_ray(query)

# -------- UPDATE --------

func _process(_delta: float) -> void:
	anchore.position = anchore.position.lerp(target_pos, pan_smooth)

	anchore.rotation.x = lerp(anchore.rotation.x, target_rot_x, rotate_smooth)
	anchore.rotation.y = lerp_angle(anchore.rotation.y, target_rot_y, rotate_smooth)


	target_zoom = clamp(target_zoom, min_zoom, max_zoom)
	mainCamera.position.z = lerp(mainCamera.position.z, target_zoom, zoom_smooth)
