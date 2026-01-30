# Camera System

![Status](https://img.shields.io/badge/status-implemented-brightgreen)

![Camera](./screenshots/cameraController.gif)

Responsibilities:

- Input (tap vs drag)
- Zoom (wheel + pinch)
- Camera modes (MOVE_XZ, MOVE_Y, ROTATE)
- Signal based mode switching
- Raycast click interaction

Signals:

- SignalManeger.request_camera_mode(mode)
- SignalManeger.mouse_interact(hit, button)

Key scripts:

- camera_controller.gd
