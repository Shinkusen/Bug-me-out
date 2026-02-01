extends Node2D

@onready var camera = $Camera2D

func _ready() -> void:
	GameController.camera_atual_cenario = camera
	GameController.transicao_entrada()
