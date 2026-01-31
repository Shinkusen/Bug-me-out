extends Node2D

var player_na_area: CharacterBody2D = null

func _physics_process(_delta: float) -> void:
	if player_na_area:
		# Envia a direção (baseada na rotação)
		player_na_area.wind_direction = Vector2.RIGHT.rotated(rotation)
		
		# NOVA LINHA: Envia a posição de origem do vento
		player_na_area.wind_source_position = global_position

func _on_area_vento_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_na_area = body

func _on_area_vento_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		if player_na_area:
			player_na_area.wind_direction = Vector2.ZERO
		player_na_area = null
