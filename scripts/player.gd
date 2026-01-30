extends CharacterBody2D

var climbing: bool = false
const SPEED = 300.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var sprite = $AnimatedSprite2D

func _process(_delta: float) -> void:
	if !GameController.in_transition_fade:
		if Input.is_action_just_pressed("climb"):
			climbing = !climbing
			if not climbing: sprite.rotation = 0

func _physics_process(delta):
	if !GameController.in_transition_fade:
		var input_direction = Input.get_vector("left", "right", "up", "down")
		
		if climbing:
			if input_direction:
				velocity = input_direction * SPEED
			else:
				velocity = velocity.move_toward(Vector2.ZERO, SPEED)
			
			if input_direction != Vector2.ZERO:
				sprite.rotation = input_direction.angle() + PI / 2
		else:
			if not is_on_floor():
				velocity.y += gravity * delta
			
			if input_direction.x:
				velocity.x = input_direction.x * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				
		move_and_slide()
