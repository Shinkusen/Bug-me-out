extends Area2D

@export var numero_da_cena: int = 1

func _on_body_entered(body):
	if body.name == "Player":
		GameController.set_checkpoint(global_position, numero_da_cena)
