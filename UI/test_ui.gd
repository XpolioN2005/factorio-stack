extends Control

var i = 1
var moax = 3

var cam: Array

@onready var lablee = $Label

func _ready():
	cam.append(GameManeger.CameraMode.MOVE_XZ)
	cam.append(GameManeger.CameraMode.MOVE_Y)
	cam.append(GameManeger.CameraMode.ROTATE)

func _on_button_pressed() -> void:
	SignalManeger.request_camera_mode.emit(cam[i])
	lablee.text = str(cam[i])
	i = i+1
	i = i % moax


