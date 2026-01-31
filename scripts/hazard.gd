extends RigidBody2D

@export var fall_delay: float = 10.0

func _ready():
	body_entered.connect(_on_body_entered)
	gravity_scale = 0
	var timer = get_tree().create_timer(fall_delay)
	await timer.timeout
	gravity_scale = 1

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("bateu")
