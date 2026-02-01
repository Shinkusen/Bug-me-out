extends Area2D

# --- REFERÊNCIAS VISUAIS ---
@export var sprites_visuais: Array[Node2D]
@export var bloqueadores_fisicos: Array[CollisionObject2D]
@onready var barra = $ProgressBar

# --- REFERÊNCIAS DE ÁUDIO (NOVO) ---
@onready var audio_scanner = $Audio_Scanner
@onready var audio_granted = $Audio_Access_Granted
@onready var audio_denied = $Audio_Access_Denied

@export var id_corpo_necessario: int = 1 

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

	if is_canalizando:
		tempo_atual += delta
		barra.value = tempo_atual
		
		# (NOVO) Toca o scanner se não estiver tocando
		if not audio_scanner.playing:
			audio_scanner.play()
		
		if tempo_atual >= tempo_total:
			completar_objetivo()
	else:
		if tempo_atual > 0:
			tempo_atual = 0
			barra.value = 0
			# (NOVO) Parou de canalizar, para o scanner
			audio_scanner.stop()

func completar_objetivo():
	completou = true
	is_canalizando = false
	barra.visible = false
	
	# (NOVO) Para o scanner e toca o som de sucesso
	audio_scanner.stop()
	audio_granted.play()
	
	for sprite in sprites_visuais:
		if sprite: sprite.visible = false
			
	for bloqueador in bloqueadores_fisicos:
		if bloqueador:
			bloqueador.visible = false
			bloqueador.process_mode = Node.PROCESS_MODE_DISABLED
	
	print("Acesso Permitido!")

func _on_body_entered(body):
	if completou: return
	
	if body.name == "Player":
		if GameController.corpos[id_corpo_necessario] == 1:
			is_canalizando = true
			barra.visible = true
		else:
			print("Acesso Negado!")
			# (NOVO) Toca som de erro imediatamente
			audio_denied.play()

func _on_body_exited(body):
	if body.name == "Player":
		is_canalizando = false
		barra.visible = false
		# (NOVO) Garante que o scanner pare se o player sair no meio
		audio_scanner.stop()
