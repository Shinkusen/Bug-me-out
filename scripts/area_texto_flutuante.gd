extends Area2D

const TEXTO_FLUTUANTE_CENA = preload("res://tscn/texto_flutuante.tscn")

@export var texto_export: String
@export var tipo: String

var texto_atual: Node = null

func _on_body_entered(body):
	if body.name == "Player":
		# Verifica se o tutorial já foi feito para não mostrar de novo
		if (tipo == "WASD" and GameController.Tutorial_WASD): return
		elif (tipo == "Espaco" and GameController.Tutorial_Espaco): return
		elif (tipo == "Checkpoint" and GameController.Tutorial_Checkpoint): return
		elif (tipo == "Eat" and GameController.Tutorial_Eat): return
		elif (tipo == "Scanner" and GameController.Tutorial_Scanner): return
		elif (tipo == "String" and GameController.Tutorial_String): return
		elif (tipo == "Fly" and GameController.Tutorial_Fly): return
		
		texto_atual = TEXTO_FLUTUANTE_CENA.instantiate()
		
		get_tree().root.add_child(texto_atual)
		texto_atual.global_position = global_position + Vector2(0, -60)
		
		texto_atual.exibir(texto_export, Color.RED)
		
		match tipo:
			"WASD": GameController.Tutorial_WASD = true
			"Espaco": GameController.Tutorial_Espaco = true
			"Checkpoint": GameController.Tutorial_Checkpoint = true
			"Eat": GameController.Tutorial_Eat = true
			"Scanner": GameController.Tutorial_Scanner = true
			"String": GameController.Tutorial_String = true
			"Fly": GameController.Tutorial_Fly = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		if is_instance_valid(texto_atual):
			texto_atual.queue_free()
