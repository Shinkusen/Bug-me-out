extends Area2D

@onready var anim = $AnimatedSprite2D

var player_ref: CharacterBody2D = null
var ja_foi_comido: bool = false 

# NOVO: Define qual índice do Array esse corpo representa (0, 1 ou 2)
@export var id_corpo: int = 0 

func _ready():
	anim.frame = 0
	
	# Verificação opcional: Se já comeu esse corpo antes (load game), já mostra comido
	if GameController.corpos[id_corpo] == 1:
		ja_foi_comido = true
		anim.frame = 1

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("eat") and player_ref != null and not ja_foi_comido:
		comer()

func comer():
	ja_foi_comido = true 
	
	player_ref.add_eatable()
	
	# NOVO: Atualiza o GameController dizendo que este corpo foi comido
	GameController.corpos[id_corpo] = 1
	print("Corpo ", id_corpo, " comido! Array atual: ", GameController.corpos)
	
	anim.frame = 1
	
	# $AudioStreamPlayer.play()
	
	GameController.player.evoluir_inseto()
	GameController.player.update_animations()
