extends ColorRect

@onready var player = get_node("../Player")

@export_group("Configurações de Luz")
@export var raio_luz: float = 0.025
@export var suavidade_borda: float = 0.4

var finalizando: bool = false

func _ready():
	# Verifica se o nome da cena atual contém "cenario_8"
	if get_tree().current_scene.name.contains("cenario_8") or get_tree().current_scene.scene_file_path.contains("cenario_8"):
		iniciar_dissolucao_final()

func _process(_delta):
	if player:
		var canvas_pos = player.get_global_transform_with_canvas().get_origin()
		var screen_size = Vector2(1200, 900)
		var normalized_pos = Vector2(
			canvas_pos.x / screen_size.x,
			canvas_pos.y / screen_size.y
		)
		
		material.set_shader_parameter("player_position", normalized_pos)
		material.set_shader_parameter("light_radius", raio_luz)
		material.set_shader_parameter("light_softness", suavidade_borda)
	else:
		# Tenta buscar o player novamente se ele sumir (ex: respawn)
		player = get_node_or_null("../Player")

func iniciar_dissolucao_final():
	finalizando = true
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "raio_luz", 1.0, 15.0)
	
	# Quando terminar, podemos até esconder o ColorRect para economizar processamento
	tween.finished.connect(func(): hide())
