extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		GameController.player.dead = true
	elif body.name == "Bloco":
		$Bloco_unico.visible = true
		$Bloco.visible = false
