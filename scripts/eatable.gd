extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var audio_eat = $Audio_Eat

var player_ref: CharacterBody2D = null
var ja_foi_comido: bool = false

@export var id_corpo: int = 0 

func _ready():
	anim.frame = 0
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
	
	GameController.corpos[id_corpo] = 1
	
	anim.frame = 1
	
	audio_eat.play()
	
	GameController.player.evoluir_inseto()
	GameController.player.update_animations()
