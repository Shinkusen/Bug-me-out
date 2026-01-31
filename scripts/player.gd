extends CharacterBody2D

# --- REFERÊNCIAS ---
@onready var sprite = $AnimatedSprite2D
@onready var web_ray = $WebRayCast
@onready var web_line = $WebLine
@onready var web_joint = $WebJoint 

# --- VARIÁVEIS ORIGINAIS ---
var climbing = false
var dead = false
var speed = 200.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

const DASH_SPEED = 800.0
const CHARGE_TIME = 1.5 

var charging = false
var charge_timer = 0.0

var dashing = false
var dash_dir = 1 
var facing = 1 

var edibles = 0

# --- VARIÁVEIS DE CONTROLE DE CENA ---
# Começa true se quiser travar logo de cara, ou controlamos pelo cenário
var in_cutscene: bool = false
var is_launched: bool = false

# --- VARIÁVEIS DA TEIA ---
enum WebState { IDLE, SHOOTING, RETRACTING, PULLING_BLOCK, CARRYING }
var current_web_state = WebState.IDLE

const MAX_WEB_LENGTH = 300.0
const MIN_WEB_LENGTH = 80.0 # Se passar disso, quebra
const JOINT_STIFFNESS = 64.0
const JOINT_DAMPING = 16.0
const WINCH_SPEED = 400.0 # Velocidade de aumentar/diminuir linha
const WEB_SPEED = 400.0 

var current_web_length = 0.0
var target_rope_length = 120.0 # Controle do tamanho da corda
var hooked_object: RigidBody2D = null

var wind_direction: Vector2 = Vector2.ZERO
var wind_source_position: Vector2 = Vector2.ZERO

var insect_level: int = 1

func _init() -> void:
	GameController.player = self

func add_eatable():
	edibles += 1

func _process(delta):
	# --- TRAVA DE CUTSCENE ---
	# Se estiver na cutscene, não processa inputs
	if in_cutscene:
		return
	
	# Input Climbing
	if (GameController.can_climb) and (Input.is_action_just_pressed("climb")):
		climbing = !climbing
		if not climbing: sprite.rotation = 0
			
	# Input da Teia (Atirar/Soltar)
	if Input.is_action_just_pressed("string"):
		if (current_web_state == WebState.IDLE) and (climbing):
			if not dashing and not charging: 
				start_shooting_web()
		elif current_web_state == WebState.CARRYING:
			drop_block()
	
	if Input.is_action_just_pressed("upar"):
		evoluir_inseto()
		update_animations()
	
	# CONTROLE DE AUMENTAR/DIMINUIR LINHA (Só funciona carregando)
	if current_web_state == WebState.CARRYING:
		if Input.is_action_pressed("aumentar_linha"):
			target_rope_length += WINCH_SPEED * delta
		elif Input.is_action_pressed("diminuir_linha"):
			target_rope_length -= WINCH_SPEED * delta
		
		# Limita o tamanho (entre 60 e 420)
		target_rope_length = clamp(target_rope_length, MIN_WEB_LENGTH, MAX_WEB_LENGTH)
		
		# Aplica ao Joint (Isso faz a corda esticar ou encolher fisicamente)
		web_joint.rest_length = target_rope_length
		web_joint.length = target_rope_length

func _physics_process(delta):
	if dead: pass
	if GameController.in_transition_fade: return
	
	# --- TRAVA DE CUTSCENE ---
	if in_cutscene:
		velocity = Vector2.ZERO # Garante que fica parado
		# Não chamamos move_and_slide() para ele ficar estático na coordenada
		return
	
	check_grade_logic()
	
	match current_web_state:
		WebState.IDLE:
			physics_movement_logic(delta)
			web_line.visible = false
		WebState.SHOOTING:
			process_web_shooting(delta)
		WebState.RETRACTING:
			process_web_retracting(delta)
		WebState.PULLING_BLOCK:
			process_pulling_block(delta)
		WebState.CARRYING:
			physics_movement_logic(delta) # Player se move
			process_carrying_logic() # Verifica quebra de linha e visual
	
	update_animations()
	push_rigid_bodies()

# ==========================================================
# LÓGICA DE MOVIMENTO
# ==========================================================
# ==========================================================
# LÓGICA DE MOVIMENTO (CORRIGIDA PARA INÉRCIA NO AR)
# ==========================================================
func physics_movement_logic(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	
	if is_launched:
		input_direction = Vector2.ZERO # Anula qualquer tecla que você apertar
		
		# Verifica se pousou.
		# A checagem 'velocity.y >= 0' garante que ele não destrave 
		# no frame 1 do lançamento enquanto ainda está subindo.
		if is_on_floor() and velocity.y >= 0:
			is_launched = false # Destrava os controles
	
	if input_direction.x > 0: facing = 1
	elif input_direction.x < 0: facing = -1
	
	# ---- CLIMBING (NA GRADE) ----
	if climbing:
		if current_web_state == WebState.CARRYING:
			sprite.rotation = Vector2.DOWN.angle() + PI / 2
			if input_direction != Vector2.ZERO:
				velocity = input_direction * speed
			else:
				velocity = velocity.move_toward(Vector2.ZERO, speed)
		elif input_direction != Vector2.ZERO:
			velocity = input_direction * speed
			sprite.rotation = input_direction.angle() + PI / 2
		else:
			velocity = velocity.move_toward(Vector2.ZERO, speed)
		
		move_and_slide()
		return 
	
	# ---- CÁLCULO DO VENTO REALISTA (Mantido) ----
	var final_wind_velocity = Vector2.ZERO
	if wind_direction != Vector2.ZERO:
		var dist = global_position.distance_to(wind_source_position)
		dist = clamp(dist, 120.0, 260.0)
		var levitation_force = 2445.0 / dist
		if current_web_state == WebState.CARRYING:
			levitation_force *= 0.5
		final_wind_velocity.y = wind_direction.y * levitation_force
		var push_force_x = 0.0
		if wind_direction.x != 0:
			push_force_x = 20000.0 / dist 
			if is_on_floor() or current_web_state == WebState.CARRYING:
				push_force_x = clamp(push_force_x, 0, 100.0)
			else:
				push_force_x = clamp(push_force_x, 0, 400.0)
		final_wind_velocity.x = wind_direction.x * push_force_x

	# ---- MOVIMENTO FÍSICO ----
	
	# 1. Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Input Horizontal + Inércia
	var target_velocity_x = 0.0
	
	if input_direction.x != 0:
		# Se o jogador está apertando tecla, obedecemos a velocidade do input
		target_velocity_x = input_direction.x * speed
	else:
		# --- AQUI ESTAVA O PROBLEMA ---
		# Se não tem input, precisamos ver se estamos no chão ou no ar
		
		if is_on_floor():
			# No chão: Freia rápido (Controle preciso)
			# Nota: Multiplicar por delta aqui deixa o freio dependente do tempo, não dos frames
			# Usei speed * 2 * delta para um freio firme, mas suave
			# Se quiser parada INSTANTÂNEA, use apenas 'speed' sem delta.
			target_velocity_x = move_toward(velocity.x - final_wind_velocity.x, 0, speed)
		else:
			# No ar: Freia MUITO pouco (Inércia/Resistência do ar)
			# Isso permite que o lançamento (launch) mantenha a velocidade X
			var air_friction = speed * delta * 0.5 
			target_velocity_x = move_toward(velocity.x - final_wind_velocity.x, 0, air_friction)
	
	velocity.x = target_velocity_x + final_wind_velocity.x
	
	# 3. Vertical + Vento Vertical
	velocity.y += final_wind_velocity.y

	# ---- Charge & Dash (Mantido) ----
	if Input.is_action_just_pressed("fly") and not dashing and not climbing:
		charging = true
		charge_timer = 0.0
		dash_dir = facing

	if Input.is_action_just_released("fly") and charging and not dashing:
		charging = false
		charge_timer = 0.0

	if charging and not dashing:
		charge_timer += delta
		velocity.x = move_toward(velocity.x, 0, speed) + final_wind_velocity.x
		if not climbing and not is_on_floor(): velocity.y += gravity * delta
		if charge_timer >= CHARGE_TIME:
			charging = false
			dashing = true
		move_and_slide()
		return 

	if Input.is_action_just_released("fly") and dashing: dashing = false

	if dashing:
		velocity.x = dash_dir * DASH_SPEED
		velocity.y = 0.0 
		move_and_slide()
		for i in range(get_slide_collision_count()):
			var c = get_slide_collision(i)
			if abs(c.get_normal().x) > 0.7:
				dashing = false
				velocity.x = 0
				break
		return 
	
	move_and_slide()

# ==========================================================
# NOVA FUNÇÃO: LANÇAMENTO BALÍSTICO
# ==========================================================
func launch_to_position(target_pos: Vector2, flight_time: float):
	# 1. Libera o player da cutscene
	in_cutscene = false
	is_launched = true
	
	# 2. Matemática de Projétil
	# Fórmula: S = S0 + V0*t + 0.5*g*t^2
	# Isolando V0: V0 = (S - S0 - 0.5*g*t^2) / t
	
	var displacement = target_pos - global_position
	var gravity_vector = Vector2(0, gravity)
	
	# Calcula a velocidade inicial necessária para atingir o alvo no tempo X
	var launch_velocity = (displacement - 0.5 * gravity_vector * (flight_time * flight_time)) / flight_time
	
	velocity = launch_velocity
	# O _physics_process normal vai assumir a partir daqui e aplicar a gravidade
	# fazendo a curva naturalmente.

# ==========================================================
# NOVA FUNÇÃO DE ANIMAÇÃO
# ==========================================================
func update_animations():
	# Montamos o prefixo baseado no nível atual. Ex: "Inseto_1_"
	var prefix = "Inseto_" + str(insect_level) + "_"
	
	if climbing:
		if current_web_state == WebState.CARRYING: # Prioridade 1: Segurando bloco (String)
			sprite.play(prefix + "String")
		elif velocity.length() > 10.0: # Prioridade 2: Se movendo (Walk)
			sprite.play(prefix + "Walk")
		else: # Prioridade 3: Parado (Idle)
			sprite.play(prefix + "Idle")
	else:
		# TEMPORARIO
		if current_web_state == WebState.CARRYING:
			sprite.play(prefix + "String")
		elif velocity.length() > 10.0:
			sprite.play(prefix + "Walk")
		else:
			sprite.play(prefix + "Idle")

# ==========================================================
# NOVA LÓGICA DA GRADE (TILEMAP)
# ==========================================================
func check_grade_logic():
	# 1. Encontra o TileMap da Grade pelo grupo
	var grade_map = get_tree().get_first_node_in_group("layer_grade")
	
	if grade_map:
		# 2. Converte a posição global do Player para a coordenada do Mapa (Grid)
		# Usamos global_position para pegar o centro/pé do player
		var map_pos = grade_map.local_to_map(grade_map.to_local(global_position))
		
		# 3. Pega os dados do azulejo (Tile) nessa coordenada
		var tile_data = grade_map.get_cell_tile_data(map_pos)
		
		# 4. Verifica se o azulejo existe E se tem a etiqueta 'can_climb' verdadeira
		if tile_data and tile_data.get_custom_data("can_climb"):
			GameController.can_climb = true
		else:
			# Se NÃO estiver no azulejo, desativa (igual ao on_body_exited antigo)
			if not GameController.in_transition_fade:
				GameController.can_climb = false
				
				# Se estava escalando e saiu da grade, para de escalar
				if climbing:
					climbing = false
					sprite.rotation = 0

# ==========================================================
# FUNÇÕES DA TEIA
# ==========================================================
func start_shooting_web():
	current_web_state = WebState.SHOOTING
	current_web_length = 0.0
	web_line.visible = true
	web_line.points[1] = Vector2.ZERO 

func process_web_shooting(delta):
	current_web_length += WEB_SPEED * delta
	web_ray.target_position = Vector2(0, current_web_length)
	web_ray.force_raycast_update()
	web_line.points[1] = Vector2(0, current_web_length)
	
	if web_ray.is_colliding():
		var collider = web_ray.get_collider()
		if collider is RigidBody2D:
			hooked_object = collider
			current_web_state = WebState.PULLING_BLOCK
		else:
			current_web_state = WebState.RETRACTING
	elif current_web_length >= MAX_WEB_LENGTH:
		current_web_state = WebState.RETRACTING

func process_web_retracting(delta):
	current_web_length -= WEB_SPEED * delta
	
	if current_web_length <= 0:
		current_web_length = 0
		current_web_state = WebState.IDLE
		web_line.visible = false
	else:
		web_line.points[1] = Vector2(0, current_web_length)

func process_pulling_block(_delta):
	if hooked_object == null:
		current_web_state = WebState.IDLE
		return
	
	var direction_to_player = global_position - hooked_object.global_position
	var distance = direction_to_player.length()
	
	web_line.points[1] = to_local(hooked_object.global_position)
	
	if distance > 120.0:
		hooked_object.linear_velocity = direction_to_player.normalized() * WEB_SPEED
	else:
		target_rope_length = max(distance, 65.0) 
		start_carrying_block()

func start_carrying_block():
	current_web_state = WebState.CARRYING
	
	web_joint.node_a = self.get_path()
	web_joint.node_b = hooked_object.get_path()
	
	web_joint.stiffness = JOINT_STIFFNESS
	web_joint.damping = JOINT_DAMPING
	
	web_joint.rest_length = target_rope_length
	web_joint.length = target_rope_length

func process_carrying_logic():
	if hooked_object == null:
		drop_block()
		return
	
	web_line.points[1] = to_local(hooked_object.global_position)
	
	var distance = global_position.distance_to(hooked_object.global_position)
	
	if distance < MIN_WEB_LENGTH:
		drop_block()

func drop_block():
	current_web_state = WebState.IDLE
	web_line.visible = false
	
	web_joint.node_a = NodePath("")
	web_joint.node_b = NodePath("")
	hooked_object = null

# ==========================================================
# UTILS
# ==========================================================
func push_rigid_bodies():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D:
			var push_direction = -collision.get_normal()
			collider.apply_central_impulse(push_direction * 100.0)

func evoluir_inseto():
	insect_level += 1
	if insect_level > 4:
		insect_level = 1
