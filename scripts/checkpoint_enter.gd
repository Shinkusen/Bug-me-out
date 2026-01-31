extends Area2D

func _on_body_entered(body):
	if body.name == "Player":
		CheckpointManager.set_checkpoint(global_position)
