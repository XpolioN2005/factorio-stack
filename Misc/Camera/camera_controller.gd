#camera controller.gd
extends Node3D

#* Camera controller also handles input since the input is depended on camera anyways

# Root -> Anchore -> MainCamera
@onready var anchore: Node3D = $Anchore
@onready var mainCamera: Camera3D = $Anchore/MainCamera

# --- CONFIGURATION ---

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
@export var min_pan: float = 0
@export var max_pan: float = 5.0
@export var min_zoom: float = 2.0
@export var max_zoom: float = 15.0

@export_category("Smooth")
@export var pan_smooth: float = 0.15
@export var rotate_smooth: float = 0.15
@export var zoom_smooth: float = 0.1


# --- INTERNAL STATE ---

var target_pan: float = 0.0
var target_rotation: float = 0.0
var target_zoom: float = 6.0

var dragging: bool = false
var last_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	target_zoom = mainCamera.position.z

func _unhandled_input(event: InputEvent) -> void:
	if is_locked:
		dragging = false
		return

	_handle_camera_motion_input(event)

	
func _handle_camera_motion_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			dragging = mb.pressed
			last_pos = mb.position

		if can_zoom and mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)


	elif event is InputEventMouseMotion and dragging:
		var mm: InputEventMouseMotion = event
		_handle_drag(mm.relative)

	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		dragging = st.pressed
		last_pos = st.position

	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		_handle_drag(sd.relative)

	elif can_zoom and event is InputEventMagnifyGesture:
		var mg: InputEventMagnifyGesture = event
		target_zoom = clamp(target_zoom - mg.factor * zoom_speed, min_zoom, max_zoom)



func _handle_drag(delta: Vector2) -> void:
	if can_pan:
		target_pan -= delta.y * pan_speed
		target_pan = clamp(target_pan, min_pan, max_pan)

	if can_rotate:
		target_rotation -= delta.x * rotate_speed


func _process(_delta: float) -> void:
	
	# Camera movement
	anchore.position.y = lerp(anchore.position.y, target_pan, pan_smooth)

	anchore.rotation.y = lerp_angle(
		anchore.rotation.y,
		target_rotation,
		rotate_smooth
	)

	target_zoom = clamp(target_zoom, min_zoom, max_zoom) # Safety net to make sure camera is inbound all the time
	mainCamera.position.z = lerp(mainCamera.position.z, target_zoom, zoom_smooth)
