extends Area2D

# Referências aos nós filhos
@onready var bloqueador_1 = $Bloqueador_1
@onready var bloqueador_2 = $Bloqueador_2
@onready var sprite_1 = $Sprite2D_1
@onready var sprite_2 = $Sprite2D_2
@onready var barra = $ProgressBar

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
	# Se já completou a tarefa, não faz mais nada
	if completou: return

	# Lógica da Canalização
	if is_canalizando:
		tempo_atual += delta
		barra.value = tempo_atual
		
		# Opcional: Se quiser que a barra siga o player, descomente a linha abaixo:
		# barra.global_position = GameController.player.global_position + Vector2(-50, 50)

		# Verifica se acabou o tempo
		if tempo_atual >= tempo_total:
			completar_objetivo()
	else:
		# Se o player saiu da área, o progresso reseta (ou diminui, se preferir)
		if tempo_atual > 0:
			tempo_atual = 0
			barra.value = 0

func completar_objetivo():
	completou = true
	is_canalizando = false
	barra.visible = false
	
	# Some com os sprites
	bloqueador_1.visible = false
	bloqueador_2.visible = false
	sprite_1.visible = false
	sprite_2.visible = false
	
	print("Canalização completa! Sprites ocultos.")

# --- SINAIS (Conecte estes sinais no editor ou use os nomes padrões) ---

func _on_body_entered(body):
	if completou: return
	
	if body.name == "Player":
		is_canalizando = true
		barra.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		is_canalizando = false
		barra.visible = false
		# Ao sair, o progresso reseta imediatamente pela lógica do _process
