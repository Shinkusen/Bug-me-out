@tool
extends Node2D

@onready var light_cone = $LightCone

@export_group("Configuração da Luz")

# O ponto onde a luz vai focar (relativo à câmera)
@export var target_point: Vector2 = Vector2(150, 50):
	set(value):
		target_point = value
		update_light_shape()

# Largura do raio na saída da lente
@export var start_width: float = 10.0:
	set(value):
		start_width = value
		update_light_shape()

# Largura do raio no destino (para cobrir o tile 2x2)
@export var end_width: float = 70.0: # ~64px seria 2 tiles de 32
	set(value):
		end_width = value
		update_light_shape()

func _ready():
	update_light_shape()

func _process(_delta):
	# Garante que atualize no editor se algo mudar
	if Engine.is_editor_hint():
		update_light_shape()

func update_light_shape():
	if not light_cone: return
	
	# Matemática Vetorial para achar os cantos do trapézio
	# 1. Direção da luz
	var direction = target_point.normalized()
	# 2. Vetor perpendicular (para saber para onde é "cima/baixo" relativo ao raio)
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# 3. Calcular os 4 pontos
	# Pontos iniciais (na lente da câmera, 0,0)
	var p1 = perpendicular * (start_width / 2.0)
	var p2 = -perpendicular * (start_width / 2.0)
	
	# Pontos finais (no alvo)
	var p3 = target_point - (perpendicular * (end_width / 2.0))
	var p4 = target_point + (perpendicular * (end_width / 2.0))
	
	# 4. Aplicar ao Polygon2D
	light_cone.polygon = PackedVector2Array([p1, p2, p4, p3])
	
	# DICA VISUAL: Criar um degradê via Vertex Colors para a luz sumir no final
	# Isso faz a ponta ficar transparente e a base sólida
	var col_solid = light_cone.color # Usa a cor base
	var col_fade = light_cone.color
	col_fade.a = 0.0 # Totalmente transparente
	
	light_cone.vertex_colors = PackedColorArray([col_solid, col_solid, col_fade, col_fade])
