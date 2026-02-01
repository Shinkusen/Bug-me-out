extends Node2D

@onready var camera = $Camera2D

@export var sprites_visuais: Array[Node2D]
@export var bloqueadores_fisicos: Array[CollisionObject2D]

func _ready() -> void:
	GameController.camera_atual_cenario = camera
	GameController.transicao_entrada()
	
	var insect_level: int = GameController.get_insect_level_atual()
	
	if insect_level >= 2:
		for sprite in sprites_visuais:
			if sprite:
				sprite.visible = false
		
		for bloqueador in bloqueadores_fisicos:
			if bloqueador:
				bloqueador.visible = false
				bloqueador.process_mode = Node.PROCESS_MODE_DISABLED
