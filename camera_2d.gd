extends Camera2D

func _ready():
	# Zoom arrière (plus petit = plus de zoom arrière)
	zoom = Vector2(0.5, 0.5)  # 50% = voit 2x plus large
	
	# Centrer la caméra
	position = Vector2(0, 0)
	
	# Activer la caméra
	enabled = true

func _process(delta):
	# Navigation au clavier (optionnel)
	var speed = 500
	if Input.is_action_pressed("ui_right"):
		position.x += speed * delta
	if Input.is_action_pressed("ui_left"):
		position.x -= speed * delta
	if Input.is_action_pressed("ui_down"):
		position.y += speed * delta
	if Input.is_action_pressed("ui_up"):
		position.y -= speed * delta
	
	# Zoom avec molette (optionnel)
	if Input.is_action_just_pressed("zoom_in"):
		zoom *= 0.9  # Zoom avant
	if Input.is_action_just_pressed("zoom_out"):
		zoom *= 1.1  # Zoom arrière

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		print(zoom)
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			if zoom.x >= 0.3:
				zoom *= 0.9  # Zoom avant
		elif event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			if zoom.y <= 0.9:
				zoom *= 1.1  # Zoom avant
