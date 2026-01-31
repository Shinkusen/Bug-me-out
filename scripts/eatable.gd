extends Area2D

var player_ref: CharacterBody2D = null

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null

func _unhandled_input(event: InputEvent) -> void:
	# Verifica: 1. Se apertou a tecla E 2. Se o player existe (está na área)
	if event.is_action_pressed("eat") and player_ref != null:
		comer()

func comer():
	player_ref.add_eatable()
	queue_free()
