extends Area2D

@export var numero_proxima_cena: int

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var caminho = "res://tscn/cenario_" + str(numero_proxima_cena) + ".tscn"
		
		GameController.transicao_saida(caminho)
