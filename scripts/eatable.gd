extends Area2D

# Mudamos a referência para o AnimatedSprite2D
@onready var anim = $AnimatedSprite2D

var player_ref: CharacterBody2D = null
var ja_foi_comido: bool = false # Variável de controle para evitar comer 2x

func _ready():
	# Garante que começa no frame 0 (Inteiro/Normal)
	anim.frame = 0

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null

func _unhandled_input(event: InputEvent) -> void:
	# Adicionamos a checagem 'not ja_foi_comido' para evitar spam da tecla
	if event.is_action_pressed("eat") and player_ref != null and not ja_foi_comido:
		comer()

func comer():
	ja_foi_comido = true # Trava a interação
	
	# Adiciona o ponto/item ao player
	player_ref.add_eatable()
	
	# Troca para o segundo frame (Frame 1 é o "comido")
	anim.frame = 1
	
	# Toca um som aqui se tiver (Opcional)
	# $AudioStreamPlayer.play()
	
	GameController.player.evoluir_inseto()
	GameController.player.update_animations()
