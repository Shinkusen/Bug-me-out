extends StaticBody2D

var player_near = null
@onready var pickup_area = $PickupArea

func _ready():
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_near = body

func _on_body_exited(body):
	if body == player_near:
		player_near = null

func _process(delta):
	if player_near and is_in_group("edible") and Input.is_action_just_pressed("eat"):
		eat(player_near)

func eat(player):
	print("comeu")
	player.add_edible()
	queue_free()
