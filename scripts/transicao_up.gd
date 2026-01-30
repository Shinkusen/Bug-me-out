extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		GameController.transicao_saida("res://tscn/cenario_2.tscn")
