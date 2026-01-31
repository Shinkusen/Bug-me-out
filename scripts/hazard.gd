extends RigidBody2D

@export var fall_delay: float

# Variável para garantir que ele só suma SE já estiver caindo (opcional, mas recomendado)
var is_falling: bool = false 

func _ready():
	# ATENÇÃO: Ativa o monitoramento via código para garantir que funcione
	contact_monitor = true
	max_contacts_reported = 1
	
	body_entered.connect(_on_body_entered)
	gravity_scale = 0
	
	var timer = get_tree().create_timer(fall_delay)
	await timer.timeout
	
	gravity_scale = 1
	is_falling = true # Agora ele pode ser destruído

func _on_body_entered(body):
	# Se quiser que suma ao bater em QUALQUER coisa:
	if is_falling: # Essa checagem evita que ele suma se encostar no teto antes de cair
		queue_free()
