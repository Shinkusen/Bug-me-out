extends Area2D

# Referências
@onready var bloqueador_1 = $Bloqueador_1
@onready var bloqueador_2 = $Bloqueador_2
@onready var sprite_1 = $Sprite2D_1
@onready var sprite_2 = $Sprite2D_2
@onready var barra = $ProgressBar

# NOVO: Qual corpo é necessário para desbloquear isso? (Para o corpo 2, coloque 1 no Inspector)
@export var id_corpo_necessario: int = 1 

# Configurações
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
	
	bloqueador_1.visible = false
	bloqueador_2.visible = false
	sprite_1.visible = false
	sprite_2.visible = false
	
	# Desativa colisão dos bloqueadores se eles tiverem colisão
	if bloqueador_1.has_method("set_collision_layer_value"):
		bloqueador_1.process_mode = Node.PROCESS_MODE_DISABLED
		bloqueador_2.process_mode = Node.PROCESS_MODE_DISABLED
	
	print("Canalização completa! Acesso liberado.")

# --- SINAIS ---

func _on_body_entered(body):
	if completou: return
	
	if body.name == "Player":
		# NOVO: Verificação Lógica
		if GameController.corpos[id_corpo_necessario] == 1:
			is_canalizando = true
			barra.visible = true
		else:
			print("ACESSO NEGADO: Você precisa comer o corpo ", id_corpo_necessario + 1, " primeiro.")
			# Aqui você pode adicionar um som de "Erro" ou um texto na tela
			# Ex: GameController.show_message("Preciso me alimentar...")

func _on_body_exited(body):
	if body.name == "Player":
		is_canalizando = false
		barra.visible = false
