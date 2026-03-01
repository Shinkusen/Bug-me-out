extends Node2D

@onready var camera = $Camera2D

@onready var titulo_final = $Titulo_Final
@onready var label_thanks = $Label
@onready var musica_final = $Audio_Final_Music

func _ready() -> void:
	GameController.camera_atual_cenario = camera
	
	if GameController.music_player:
		GameController.music_player.stop()
	musica_final.play()
	
	GameController.transicao_entrada()
	
	titulo_final.pivot_offset = titulo_final.size / 2
	label_thanks.visible_ratio = 0.0 # Letras ficam escondidas (0%)
	
	iniciar_animacao_titulo()
	sequencia_final_thanks()

func iniciar_animacao_titulo():
	var tween_fade = create_tween()
	tween_fade.tween_property(titulo_final, "modulate:a", 1.0, 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	var tween_pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_pulse.tween_property(titulo_final, "scale", Vector2(1.03, 1.03), 1.5)
	tween_pulse.tween_property(titulo_final, "scale", Vector2(1.0, 1.0), 1.5)

func sequencia_final_thanks():
	await get_tree().create_timer(7.0).timeout
	
	var tween_typewriter = create_tween()
	tween_typewriter.tween_property(label_thanks, "visible_ratio", 1.0, 10.0).set_trans(Tween.TRANS_LINEAR)
	
	await tween_typewriter.finished
	await get_tree().create_timer(1.5).timeout
	
	var tween_fade_subtitulo = create_tween()
	tween_fade_subtitulo.tween_property(label_thanks, "modulate:a", 0.5, 3.0).set_trans(Tween.TRANS_SINE)
