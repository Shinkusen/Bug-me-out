extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		GameController.can_climb = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" and !GameController.in_transition_fade:
		GameController.can_climb = false
		GameController.player.climbing = false
		GameController.player.sprite.rotation = 0
