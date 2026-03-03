extends Area2D

# --- REFERÊNCIAS VISUAIS ---
@export var sprites_visuais: Array[Node2D]
@export var bloqueadores_fisicos: Array[CollisionObject2D]
@onready var barra = $CanvasLayer/ProgressBar

# --- REFERÊNCIAS DE ÁUDIO (NOVO) ---
@onready var audio_scanner = $Audio_Scanner
@onready var audio_granted = $Audio_Access_Granted
@onready var audio_denied = $Audio_Access_Denied

@export var id_corpo_necessario: int = 1 

var tempo_total: float = 5.0
var tempo_atual: float = 0.0
var pode_canalizar: bool = false
var completou: bool = false

func _ready():
	barra.value = 0
	barra.max_value = tempo_total
	barra.visible = false

func _process(delta):
	if completou: return
	
	if GameController.player.facing_y == 1 and pode_canalizar:
		tempo_atual += delta
		barra.visible = true
		barra.value = tempo_atual
		
		if not audio_scanner.playing:
			audio_scanner.play()
		
		if tempo_atual >= tempo_total:
			completar_objetivo()
	else:
		if tempo_atual > 0:
			tempo_atual = 0
			barra.value = 0
			barra.visible = false
			audio_scanner.stop()

func completar_objetivo():
	completou = true
	pode_canalizar = false
	barra.visible = false
	
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
			pode_canalizar = true
		else:
			audio_denied.play()

func _on_body_exited(body):
	if body.name == "Player":
		pode_canalizar = false
		barra.visible = false
		audio_scanner.stop()
