extends Control

@onready var btn_jogar = $Jogar
@onready var btn_sair = $Sair

func _ready():
	animar_botao(btn_jogar)
	animar_botao(btn_sair)

func animar_botao(botao: Button):
	# --- 1. CONFIGURAÇÃO INICIAL ---
	botao.add_theme_font_size_override("font_size", 36)
	botao.modulate.a = 0.3

	# --- 2. ANIMAÇÃO DA FONTE (Oscilar Tamanho) ---
	var tween_fonte = create_tween().set_loops() # set_loops() faz repetir para sempre
	tween_fonte.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT) # Deixa o movimento suave
	
	tween_fonte.tween_property(botao, "theme_override_font_sizes/font_size", 39, 0.75)
	tween_fonte.tween_property(botao, "theme_override_font_sizes/font_size", 36, 0.75)

	# --- 3. ANIMAÇÃO DA TRANSPARÊNCIA (Oscilar Fundo) ---
	var tween_alpha = create_tween().set_loops()
	tween_alpha.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween_alpha.tween_property(botao, "modulate:a", 0.6, 1.0)
	tween_alpha.tween_property(botao, "modulate:a", 0.7, 1.0)

func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://tscn/cenario_1.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
