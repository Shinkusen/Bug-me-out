extends Control

@onready var label = $Label

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func exibir(mensagem: String, cor: Color = Color.WHITE, tempo_duracao: float = 5.0):
	label.text = mensagem
	label.modulate = cor
	
	# --- AJUSTE DO PIVÔ (Crucial para oscilar do centro) ---
	# Esperamos um frame para o Godot calcular o tamanho real do texto novo
	await get_tree().process_frame
	
	# Coloca o ponto de ancoragem no meio exato do texto
	label.pivot_offset = label.size / 2
	
	iniciar_animacao_pulsar()
	
	# Opcional: Destroi o texto após X segundos para não acumular na tela
	# Se quiser que fique para sempre, apague as 3 linhas abaixo.
	await get_tree().create_timer(tempo_duracao).timeout
	queue_free()

func iniciar_animacao_pulsar():
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(label, "scale", Vector2(1.035, 1.035), 0.5)
	tween.tween_property(label, "scale", Vector2(0.965, 0.965), 0.5)
