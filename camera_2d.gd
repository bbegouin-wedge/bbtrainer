extends Camera2D

func _ready():
	# Zoom arrière (plus petit = plus de zoom arrière)
	zoom = Vector2(0.5, 0.5)  # 50% = voit 2x plus large
	
	# Centrer la caméra
	position = Vector2(0, 0)
	
	# Activer la caméra
	enabled = true

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			if zoom.x >= 0.2:
				zoom *= 0.9  # Zoom avant
				return
		elif event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			if zoom.y <= 0.9:
				zoom *= 1.1
				return  # Zoom avant
