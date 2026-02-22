extends Control

@onready var titulo = $Titulo
@onready var btn_jogar = $Jogar
@onready var btn_sair = $Sair

func _ready():
	animar_titulo_sutil()
	configurar_botoes_imagem(btn_jogar)
	configurar_botoes_imagem(btn_sair)

func animar_titulo_sutil():
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(titulo, "scale", Vector2(1.015, 1.015), 1.0)
	tween.tween_property(titulo, "scale", Vector2(1.0, 1.0), 1.0)

func configurar_botoes_imagem(botao: Control):
	botao.modulate = Color(0.7, 0.7, 0.7, 1.0)
	
	botao.mouse_entered.connect(func():
		var t = create_tween()
		t.tween_property(botao, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
	)
	
	botao.mouse_exited.connect(func():
		var t = create_tween()
		t.tween_property(botao, "modulate", Color(0.7, 0.7, 0.7, 1.0), 0.1)
	)

func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://tscn/cenario_1.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
