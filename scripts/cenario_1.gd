extends Node2D

@onready var camera = $Camera2D
@onready var faiscas = $Faiscas

@onready var mascara = $Mascara_Animacao_Inicial

@onready var explosao_core = $GrupoExplosao/ExplosaoCore
@onready var explosao_fumaca = $GrupoExplosao/Explosao
@onready var explosao_sparks = $GrupoExplosao/ExplosaoSparks

const POSICAO_INICIAL = Vector2(632.0, 470.0)
const POSICAO_FINAL = Vector2(1074.0, 686.0)

var tween_mascara: Tween

func _ready():
	GameController.camera_atual_cenario = camera
	
	# --- CONFIGURAÇÃO INICIAL ---
	if GameController.player:
		GameController.player.global_position = POSICAO_INICIAL
		GameController.player.in_cutscene = true
		
		GameController.player.visible = false 
	
	mascara.visible = true
	mascara.scale = Vector2(0.2, 0.2)
		
	iniciar_sequencia_particulas()

func iniciar_sequencia_particulas():
	# --- T = 0 segundos ---
	faiscas.emitting = true
	
	explosao_core.emitting = false
	explosao_fumaca.emitting = false
	explosao_sparks.emitting = false
	
	# Espera 3 segundos
	await get_tree().create_timer(3.0).timeout
	
	# --- T = 3 segundos (CANALIZAÇÃO) ---
	explosao_core.emitting = true 
	
	# 2. INICIA A ANIMAÇÃO DA MÁSCARA PULSANDO "BEM DE LEVE"
	tween_mascara = create_tween().set_loops()
	tween_mascara.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween_mascara.tween_property(mascara, "scale", mascara.scale * 1.05, 0.2)
	tween_mascara.tween_property(mascara, "scale", mascara.scale, 0.2)
	
	# Espera 3 segundos direto (Do segundo 3 ao 6)
	await get_tree().create_timer(3.0).timeout
	
	# --- T = 6 segundos (O ESTOURO E LANÇAMENTO) ---
	
	# 3. FINALIZA A MÁSCARA E MOSTRA O PLAYER
	if tween_mascara:
		tween_mascara.kill() # Para a animação de pulsar
	mascara.visible = false
	
	if GameController.player:
		GameController.player.visible = true # O PLAYER APARECE!
	
	# Efeitos da explosão
	explosao_core.emitting = false 
	explosao_fumaca.emitting = true
	explosao_sparks.emitting = true
	
	# --- LANÇA O PLAYER ---
	if GameController.player:
		GameController.player.launch_to_position(POSICAO_FINAL, 1.2) 
	
	# Espera 2 segundos para a fumaça se dissipar (Chegamos em T = 8s)
	await get_tree().create_timer(2.0).timeout
	
	# --- T = 8 segundos (FIM) ---
	explosao_fumaca.emitting = false
	explosao_sparks.emitting = false
	#faiscas.emitting = false
