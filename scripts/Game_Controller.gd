extends Node

var player: CharacterBody2D

var camera_atual_cenario: Camera2D
var _global_fade_rect: ColorRect
var in_transition_fade: bool = false
var proxima_cena_path: String = ""
var can_climb: bool = false

func _ready() -> void:
	_criar_tela_preta_global()

func _criar_tela_preta_global():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	_global_fade_rect = ColorRect.new()
	_global_fade_rect.color = Color.BLACK
	_global_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_global_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_global_fade_rect.modulate.a = 0.0
	canvas.add_child(_global_fade_rect)

func transicao_saida(path_cena: String):
	if camera_atual_cenario == null: return
	
	proxima_cena_path = path_cena
	in_transition_fade = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera_atual_cenario, "position", Vector2(600, -450), 1.5)
	tween.tween_property(_global_fade_rect, "modulate:a", 1.0, 1.5)
	tween.chain().tween_callback(_trocar_cena_arquivo)

func _trocar_cena_arquivo():
	get_tree().change_scene_to_file(proxima_cena_path)

func transicao_entrada():
	if camera_atual_cenario == null: return
	
	camera_atual_cenario.position = Vector2(600, 1350)
	in_transition_fade = true 
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(camera_atual_cenario, "position", Vector2(600, 450), 1.5)
	tween.tween_property(_global_fade_rect, "modulate:a", 0.0, 1.5)
	tween.chain().tween_callback(liberar_jogo)

func liberar_jogo():
	in_transition_fade = false
