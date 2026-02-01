extends Area2D

# --- REFERÊNCIAS GENÉRICAS (ARRAYS) ---
@export var sprites_visuais: Array[Node2D]
@export var bloqueadores_fisicos: Array[CollisionObject2D]

@onready var barra = $ProgressBar

@export var id_corpo_necessario: int = 1

# Configurações de Tempo
var tempo_total: float = 5.0
var tempo_atual: float = 0.0
var is_canalizando: bool = false
var completou: bool = false

func _ready():
	barra.value = 0
	barra.max_value = tempo_total
	barra.visible = false

func _process(delta):
	if completou: return

	# Lógica da Canalização
	if is_canalizando:
		tempo_atual += delta
		barra.value = tempo_atual
		
		if tempo_atual >= tempo_total:
			completar_objetivo()
	else:
		if tempo_atual > 0:
			tempo_atual = 0
			barra.value = 0

func completar_objetivo():
	completou = true
	is_canalizando = false
	barra.visible = false
	
	# --- LOOP PARA DESATIVAR TUDO NA LISTA ---
	
	# 1. Some com todos os Sprites visuais cadastrados
	for sprite in sprites_visuais:
		if sprite:
			sprite.visible = false
			
	# 2. Desativa todos os Bloqueadores físicos cadastrados
	for bloqueador in bloqueadores_fisicos:
		if bloqueador:
			bloqueador.visible = false # Some visualmente se tiver sprite atrelado
			# Desativa a física completamente (colisão para de funcionar)
			bloqueador.process_mode = Node.PROCESS_MODE_DISABLED
	
	print("Canalização completa! Todos os bloqueios removidos.")

# --- SINAIS ---

func _on_body_entered(body):
	if completou: return
	
	if body.name == "Player":
		# Verificação Lógica
		if GameController.corpos[id_corpo_necessario] == 1:
			is_canalizando = true
			barra.visible = true
		else:
			print("ACESSO NEGADO: Preciso comer o corpo ", id_corpo_necessario + 1)

func _on_body_exited(body):
	if body.name == "Player":
		is_canalizando = false
		barra.visible = false
