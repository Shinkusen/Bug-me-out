extends CharacterBody2D

var climbing = false
const SPEED = 300.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var sprite = $AnimatedSprite2D

const DASH_SPEED = 900.0
const CHARGE_TIME = 1.5 # segundos pra carregar (ajuste aqui)

var charging = false
var charge_timer = 0.0

var dashing = false
var dash_dir = 1 # 1 right -1 left
var facing = 1 

var edibles = 0

func add_edible():
	edibles += 1
	print("Edibles eaten:", edibles)

func _process(_delta):
	if Input.is_action_just_pressed("climb"):
		climbing = !climbing
		if not climbing:
			sprite.rotation = 0

func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")

	if input_direction.x > 0:
		facing = 1
	elif input_direction.x < 0:
		facing = -1

	# ---- Movement ----
	if climbing:
		if input_direction != Vector2.ZERO:
			velocity = input_direction * SPEED
		else:
			velocity = velocity.move_toward(Vector2.ZERO, SPEED)

		if input_direction != Vector2.ZERO:
			sprite.rotation = input_direction.angle() + PI / 2
	else:
		if not is_on_floor():
			velocity.y += gravity * delta

		if input_direction.x != 0:
			velocity.x = input_direction.x * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
	# ---- Charge -----
	if Input.is_action_just_pressed("fly") and not dashing and not climbing:
		charging = true
		charge_timer = 0.0
		dash_dir = facing

	# Cancels dash if key is released before time
	if Input.is_action_just_released("fly") and charging and not dashing:
		charging = false
		charge_timer = 0.0

	if charging and not dashing:
		charge_timer += delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
		# mantém gravidade normal
		if not climbing and not is_on_floor():
			velocity.y += gravity * delta

		# Quando completa, começa o dash
		if charge_timer >= CHARGE_TIME:
			charging = false
			dashing = true

		move_and_slide()
		return

	# ---- Dash ----
	if Input.is_action_just_released("fly") and dashing:
		dashing = false

	if dashing:
		velocity.x = dash_dir * DASH_SPEED
		velocity.y = 0.0  # Doesnt fall while dashing
		move_and_slide()

		# Stops on a wall
		for i in range(get_slide_collision_count()):
			var c = get_slide_collision(i)
			if abs(c.get_normal().x) > 0.7:
				dashing = false
				velocity.x = 0
				break
		return
	
	move_and_slide()
