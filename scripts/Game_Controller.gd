extends Node

var player: CharacterBody2D

var camera_atual_cenario: Camera2D
var _global_fade_rect: ColorRect
var in_transition_fade: bool = false
var proxima_cena_path: String = ""
var can_climb: bool = false

var checkpoint_position = Vector2.ZERO
var checkpoint_cena: int = 1

var is_respawning: bool = false

const PASTA_CENAS = "res://tscn/"

# 0 = não comido, 1 = comido
var corpos: Array = [0, 0, 0]

func _ready() -> void:
	_criar_tela_preta_global()

func get_insect_level_atual() -> int:
	var nivel = 1
	for status in corpos:
		if status == 1:
			nivel += 1
	return nivel

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

func set_checkpoint(pos: Vector2, num_cena: int):
	checkpoint_position = pos
	checkpoint_cena = num_cena
	#print("Checkpoint salvo: Cena ", checkpoint_cena, " em ", checkpoint_position)

func reload_scene():
	# Ativa a flag para avisar o próximo player que ele deve ir para o checkpoint
	is_respawning = true
	
	if checkpoint_cena <= 3:
		corpos = [0, 0, 0]
	elif checkpoint_cena <= 5:
		corpos = [1, 0, 0]
	elif checkpoint_cena <= 8:
		corpos = [1, 1, 0]
	elif checkpoint_cena <= 11:
		corpos = [1, 1, 1]
	
	# Monta o caminho: "res://cenario_2.tscn", por exemplo
	var nome_cena = "cenario_" + str(checkpoint_cena) + ".tscn"
	var caminho_completo = PASTA_CENAS + nome_cena
	
	# Troca para a cena correta (seja a mesma ou uma anterior)
	# Usamos call_deferred para evitar travamentos durante física
	get_tree().change_scene_to_file.call_deferred(caminho_completo)
