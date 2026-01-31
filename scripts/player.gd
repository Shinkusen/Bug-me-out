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

func _init() -> void:
	GameController.player = self

func add_edible():
	edibles += 1
	print("Edibles eaten:", edibles)

func _process(delta):
	# Input Climbing
	if GameController.can_climb and Input.is_action_just_pressed("climb"):
		climbing = !climbing
		if not climbing: sprite.rotation = 0
			
	# Input da Teia (Atirar/Soltar)
	if Input.is_action_just_pressed("string"):
		if current_web_state == WebState.IDLE:
			if not dashing and not charging: 
				start_shooting_web()
		elif current_web_state == WebState.CARRYING:
			drop_block()
	
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
	if dead: #implementar a logica de morte
		pass
	if GameController.in_transition_fade: return
	
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
	
	push_rigid_bodies()

# ==========================================================
# LÓGICA DE MOVIMENTO
# ==========================================================
func physics_movement_logic(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction.x > 0: facing = 1
	elif input_direction.x < 0: facing = -1

	# ---- CLIMBING ----
	if climbing:
		if input_direction != Vector2.ZERO:
			velocity = input_direction * speed
			sprite.rotation = input_direction.angle() + PI / 2
		else:
			velocity = velocity.move_toward(Vector2.ZERO, speed)
		
		# Se quiser vento na grade, insira lógica simples aqui
		move_and_slide()
		return 
	
	# ---- CÁLCULO DO VENTO REALISTA (ATENUAÇÃO) ----
	var final_wind_velocity = Vector2.ZERO
	
	if wind_direction != Vector2.ZERO:
		# 1. Calcular Distância
		# Usamos distance_to para saber quão longe estamos do ventilador
		var dist = global_position.distance_to(wind_source_position)
		
		# Clamp para segurança (evita divisão por zero ou força infinita se encostar no ventilador
		dist = clamp(dist, 120.0, 260.0)
		
		# 2. Calcular Força de Levitação (Eixo Y)
		# Matemática: Queremos que em 150px a força seja igual a Gravidade (~16.3 per frame)
		# Constante K = Força_Desejada * Distancia = 16.3 * 150 = 2445
		var levitation_force = 2445.0 / dist
		
		# Aplicamos essa força na direção Y
		# Se estiver segurando bloco, reduzimos a força pela metade (fica mais pesado)
		if current_web_state == WebState.CARRYING:
			levitation_force *= 0.5
			
		final_wind_velocity.y = wind_direction.y * levitation_force

		# 3. Calcular Empurrão Horizontal (Eixo X)
		# Também usamos a distância: mais perto = empurrão mais forte
		var push_force_x = 0.0
		if wind_direction.x != 0:
			# Fórmula empírica: Perto (50px) = 400 speed, Longe (300px) = 66 speed
			push_force_x = 20000.0 / dist 
			
			# Regra de Jogabilidade: Se estiver no chão, o atrito segura um pouco
			if is_on_floor() or current_web_state == WebState.CARRYING:
				push_force_x = clamp(push_force_x, 0, 100.0) # Teto máximo de 100 no chão
			else:
				push_force_x = clamp(push_force_x, 0, 400.0) # Teto máximo de 400 no ar
		
		final_wind_velocity.x = wind_direction.x * push_force_x

	# ---- MOVIMENTO FÍSICO ----
	
	# 1. Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Input Horizontal + Vento Horizontal
	var target_velocity_x = 0.0
	if input_direction.x != 0:
		target_velocity_x = input_direction.x * speed
	else:
		# Desacelera a inércia do player, mas mantém o vento empurrando
		target_velocity_x = move_toward(velocity.x - final_wind_velocity.x, 0, speed)
	
	velocity.x = target_velocity_x + final_wind_velocity.x
	
	# 3. Vertical + Vento Vertical
	# O vento vertical age como aceleração (soma-se frame a frame)
	velocity.y += final_wind_velocity.y

	# ---- Charge & Dash ----
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
	
	# Puxa visualmente até chegar na distancia de carregar
	var direction_to_player = global_position - hooked_object.global_position
	var distance = direction_to_player.length()
	
	web_line.points[1] = to_local(hooked_object.global_position)
	
	# Usamos uma margem de segurança. Se chegou a 120 (ou menos), conecta.
	if distance > 120.0:
		hooked_object.linear_velocity = direction_to_player.normalized() * WEB_SPEED
	else:
		# Define o tamanho inicial da corda como o tamanho atual (ou 120)
		target_rope_length = max(distance, 65.0) 
		start_carrying_block()

func start_carrying_block():
	current_web_state = WebState.CARRYING
	
	# Configura a Mola
	web_joint.node_a = self.get_path()
	web_joint.node_b = hooked_object.get_path()
	
	# Aplica os novos valores de física para ficar mais firme
	web_joint.stiffness = JOINT_STIFFNESS
	web_joint.damping = JOINT_DAMPING
	
	web_joint.rest_length = target_rope_length
	web_joint.length = target_rope_length

func process_carrying_logic():
	if hooked_object == null:
		drop_block()
		return
	
	# Atualiza linha visual
	web_line.points[1] = to_local(hooked_object.global_position)
	
	# VERIFICAÇÃO DE QUEBRA AUTOMÁTICA
	var distance = global_position.distance_to(hooked_object.global_position)
	
	# Se ficar muito perto (< 60), corta a teia para evitar glitch
	if distance < MIN_WEB_LENGTH:
		drop_block()

func drop_block():
	current_web_state = WebState.IDLE
	web_line.visible = false
	
	# Desconecta a mola
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
