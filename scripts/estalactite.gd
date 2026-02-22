extends RigidBody2D

@export var is_area: bool
@export var is_killable: bool
@export var distance: int
@export var life_time_particulas: float

const respawn_time: float = 15.0
var ativo: bool = true

@onready var posicao_inicial: Vector2 = global_position
@onready var sprite = $Sprite2D
@onready var shape = $CollisionShape2D

func _ready():
	# Ambos estão definidos no inspector, somente por garantia
	contact_monitor = true
	max_contacts_reported = 1
	reset_estalactite()
	
	if distance != 0:
		$Area2D.position.y = (distance / 2.0) * 60
		# Usamos set_deferred para evitar avisos do motor de física
		$Area2D/CollisionShape2D.shape.set_deferred("size", Vector2($Area2D/CollisionShape2D.shape.size.x, distance * 60))
		$Faiscas.lifetime = life_time_particulas

func reset_estalactite():
	set_deferred("freeze", true)
	global_position = posicao_inicial
	gravity_scale = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	
	show()
	shape.disabled = false
	ativo = true
	
	$Faiscas.emitting = is_killable
	
	# Recriar ou reativar a área de detecção se for de queda
	if is_area:
		$Area2D.monitoring = true
		$Area2D.show()

# --- SINAL DA ÁREA DE QUEDA ---
func _on_area_2d_body_entered(body):
	if !is_area or !ativo: return
	
	if body.name == "Player":
		# 1. Usamos set_deferred para desativar a física (freeze) de forma segura
		set_deferred("freeze", false) 
		
		# 2. Ativamos a gravidade
		gravity_scale = 1
		
		# 3. Usamos set_deferred para desligar o monitoramento da área
		$Area2D.set_deferred("monitoring", false)
		
		# Esconder o visual da área pode ser imediato, não afeta a física
		$Area2D.hide()

# --- SINAL DE COLISÃO DO CORPO ---
func _on_body_entered(body):
	if !is_killable or !ativo: return
	
	if body.name == "Player":
		GameController.player.dead = true
	
	iniciar_respawn()

func iniciar_respawn():
	ativo = false
	hide() # Esconde o estalactite
	shape.set_deferred("disabled", true) # Desativa a colisão para não matar o player invisível
	
	# Espera o tempo de respawn
	await get_tree().create_timer(respawn_time).timeout
	
	reset_estalactite()
