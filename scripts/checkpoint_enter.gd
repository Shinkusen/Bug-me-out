extends Area2D

@export var numero_da_cena: int

func _ready() -> void:
	if GameController.checkpoint_cena >= numero_da_cena:
		$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		$Sprite2D.modulate = Color(0.491, 0.491, 0.491, 1.0)

func _on_body_entered(body):
	if body.name == "Player":
		if GameController.checkpoint_cena < numero_da_cena:
			$Respawn.emitting = true
			$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		GameController.set_checkpoint(global_position, numero_da_cena)
