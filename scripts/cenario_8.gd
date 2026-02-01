extends Node2D

@onready var camera = $Camera2D

# --- NOVAS REFERÊNCIAS (Baseadas na sua imagem da cena) ---
@onready var titulo_final = $Titulo_Final
@onready var label_thanks = $Label

func _ready() -> void:
	GameController.camera_atual_cenario = camera
	# A transição de entrada do GameController já faz um fade da tela preta.
	# Se você quiser que o título só comece a aparecer DEPOIS que a tela clarear,
	# você pode usar um 'await' aqui. Vou deixar sem por enquanto para começar junto.
	GameController.transicao_entrada()
	
	# --- CONFIGURAÇÃO INICIAL ---
	# 1. Garante que começam invisíveis (transparentes)
	titulo_final.modulate.a = 0.0
	label_thanks.modulate.a = 0.0
	
	# 2. Ajusta o pivô do título para o centro.
	# Isso é crucial para que ele oscile de tamanho a partir do meio, 
	# e não do canto superior esquerdo.
	titulo_final.pivot_offset = titulo_final.size / 2
	
	# --- INICIA AS ANIMAÇÕES ---
	iniciar_animacao_titulo()
	iniciar_animacao_subtitle()

func iniciar_animacao_titulo():
	# PARTE 1: FADE IN (Aparecer)
	var tween_fade = create_tween()
	# Vai do alpha 0 atual até 1.0 em 2.5 segundos (ajuste o tempo se quiser mais rápido/lento)
	tween_fade.tween_property(titulo_final, "modulate:a", 1.0, 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# PARTE 2: OSCILAÇÃO (Pulsar tamanho)
	# set_loops() faz repetir para sempre.
	var tween_pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Aumenta 3% do tamanho em 1.5 segundos
	tween_pulse.tween_property(titulo_final, "scale", Vector2(1.03, 1.03), 1.5)
	# Volta ao tamanho normal em 1.5 segundos
	tween_pulse.tween_property(titulo_final, "scale", Vector2(1.0, 1.0), 1.5)

func iniciar_animacao_subtitle():
	var tween = create_tween()
	
	# 1. Espera 1 segundo antes de começar
	tween.tween_interval(1.0)
	
	# 2. Faz o Fade In do alpha 0 até 1.0 em 2 segundos
	tween.tween_property(label_thanks, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
