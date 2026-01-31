extends RigidBody2D

@export var hazard_id: String = "A"
@export var fall_delay: float = 1.0

var is_falling = false
var activated = false

func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)

	gravity_scale = 0
	add_to_group("hazard_" + hazard_id)

func activate():
	if activated:
		return
	activated = true

	await get_tree().create_timer(fall_delay).timeout
	gravity_scale = 1
	sleeping = false
	is_falling = true

func _on_body_entered(body):
	if body.name == "Player":
		body.dead = true

	if is_falling:
		queue_free()
