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
var in_cutscene: bool = false
var is_launched: bool = false

# --- VARIÁVEIS NOVAS (ANIMAÇÃO) ---
var is_changing_perspective: bool = false # Trava o player durante a animação de subir/descer

# --- VARIÁVEIS DA TEIA ---
enum WebState { IDLE, SHOOTING, RETRACTING, PULLING_BLOCK, CARRYING }
var current_web_state = WebState.IDLE

const MAX_WEB_LENGTH = 300.0
const MIN_WEB_LENGTH = 80.0 
const JOINT_STIFFNESS = 64.0
const JOINT_DAMPING = 16.0
const WINCH_SPEED = 400.0 
const WEB_SPEED = 400.0 

var current_web_length = 0.0
var target_rope_length = 120.0 
var hooked_object: RigidBody2D = null

var wind_direction: Vector2 = Vector2.ZERO
var wind_source_position: Vector2 = Vector2.ZERO

var insect_level: int = 1

func _init() -> void:
	GameController.player = self

func _ready():
	# Conecta o sinal para saber quando a animação "Perspectiva" acabou
	sprite.animation_finished.connect(_on_animation_finished)
	
	if GameController.is_respawning:
		global_position = GameController.checkpoint_position
		GameController.is_respawning = false

func add_eatable():
	edibles += 1

func _process(delta):
	if in_cutscene: return
	
	# --- INPUT CLIMBING (ATUALIZADO PARA PERSPECTIVA) ---
	# Só aceita input se não estiver no meio de uma transição de perspectiva
	if (GameController.can_climb) and (Input.is_action_just_pressed("climb")) and not is_changing_perspective:
		try_change_perspective()
			
	# --- INPUT DA TEIA (Nível 3+) ---
	if Input.is_action_just_pressed("string"):
		if insect_level >= 3: # Validação de Nível
			if (current_web_state == WebState.IDLE) and (climbing):
				if not dashing and not charging: 
					start_shooting_web()
			elif current_web_state == WebState.CARRYING:
				drop_block()
		else:
			print("Nível insuficiente para usar Teia")
	
	# CONTROLE DE AUMENTAR/DIMINUIR LINHA
	if current_web_state == WebState.CARRYING:
		if Input.is_action_pressed("aumentar_linha"):
			target_rope_length += WINCH_SPEED * delta
		elif Input.is_action_pressed("diminuir_linha"):
			target_rope_length -= WINCH_SPEED * delta
		
		target_rope_length = clamp(target_rope_length, MIN_WEB_LENGTH, MAX_WEB_LENGTH)
		web_joint.rest_length = target_rope_length
		web_joint.length = target_rope_length

func _physics_process(delta):
	if dead:
		dead = false
		GameController.reload_scene()
		return
	
	if GameController.in_transition_fade: return
	
	# Se estiver na cutscene ou mudando de perspectiva, fica parado
	if in_cutscene or is_changing_perspective:
		velocity = Vector2.ZERO 
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
			physics_movement_logic(delta) 
			process_carrying_logic() 
	
	update_animations()
	push_rigid_bodies()

# ==========================================================
# LÓGICA DE MOVIMENTO (COM FLIP HORIZONTAL)
# ==========================================================
func physics_movement_logic(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	
	if is_launched:
		input_direction = Vector2.ZERO 
		if is_on_floor() and velocity.y >= 0:
			is_launched = false 
	
	# --- ATUALIZAÇÃO DA DIREÇÃO E OLHAR (FLIP) ---
	if input_direction.x > 0: 
		facing = 1
		# Se não estiver escalando, olha para a direita
		if not climbing: sprite.flip_h = false 
	elif input_direction.x < 0: 
		facing = -1
		# Se não estiver escalando, vira para a esquerda
		if not climbing: sprite.flip_h = true 
	
	# ---- CLIMBING (NA GRADE) ----
	if climbing:
		# Garante que na grade o sprite não fique espelhado (a rotação cuida disso)
		sprite.flip_h = false 
		
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
		target_velocity_x = input_direction.x * speed
	else:
		if is_on_floor():
			target_velocity_x = move_toward(velocity.x - final_wind_velocity.x, 0, speed)
		else:
			var air_friction = speed * delta * 0.5 
			target_velocity_x = move_toward(velocity.x - final_wind_velocity.x, 0, air_friction)
	
	velocity.x = target_velocity_x + final_wind_velocity.x
	
	# 3. Vertical + Vento Vertical
	velocity.y += final_wind_velocity.y

	# ---- Charge & Dash (Mantido) ----
	if insect_level >= 4:
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
# LANÇAMENTO BALÍSTICO
# ==========================================================
func launch_to_position(target_pos: Vector2, flight_time: float):
	in_cutscene = false
	is_launched = true
	
	var displacement = target_pos - global_position
	var gravity_vector = Vector2(0, gravity)
	var launch_velocity = (displacement - 0.5 * gravity_vector * (flight_time * flight_time)) / flight_time
	
	velocity = launch_velocity

# ==========================================================
# NOVA LÓGICA DE ANIMAÇÃO CENTRALIZADA (ATUALIZADA)
# ==========================================================
func update_animations():
	# Se estiver mudando de perspectiva, não atrapalha a animação One Shot
	if is_changing_perspective:
		return

	var prefix = "Inseto_" + str(insect_level) + "_"
	
	# 1. Prioridade Máxima: Dash (Fly) - Só Nível 4
	if dashing:
		_try_play_animation(prefix + "Fly")
		return

	# 2. Prioridade: String (Carregando bloco) - Só Nível 3+
	if current_web_state == WebState.CARRYING:
		_try_play_animation(prefix + "String")
		return

	# 3. Lógica de Movimento
	if climbing:
		# --- NA GRADE (VERTICAL) ---
		# Aqui mantemos a lógica de separar Andar de Parado
		if velocity.length() > 10.0:
			_try_play_animation(prefix + "Walk_Vertical")
		else:
			_try_play_animation(prefix + "Idle")
	else:
		# --- NO CHÃO (HORIZONTAL) ---
		# CORREÇÃO: Você pediu para usar o Walk Horizontal como se fosse o Idle.
		# Então removemos a checagem de velocidade (velocity.x > 10) e o "else: Idle".
		# Ele vai tocar Walk_Horizontal o tempo todo enquanto estiver no chão.
		_try_play_animation(prefix + "Walk_Horizontal")

# Função auxiliar segura para tocar animação (evita erro se faltar assets)
func _try_play_animation(anim_name: String):
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		# Fallback: Se não tiver Walk_Horizontal, tenta Walk, ou Idle
		# Isso previne o jogo de travar ou ficar invisível no Nível 4 incompleto
		if "Walk" in anim_name:
			if sprite.sprite_frames.has_animation("Inseto_" + str(insect_level) + "_Idle"):
				sprite.play("Inseto_" + str(insect_level) + "_Idle")
		# Apenas um print de debug para avisar o dev
		# print("Animação faltando: ", anim_name)

# ==========================================================
# GERENCIAMENTO DE PERSPECTIVA (ANIM & LOGIC)
# ==========================================================
func try_change_perspective():
	var prefix = "Inseto_" + str(insect_level) + "_"
	var anim_name = ""
	
	if not climbing:
		# Quer Subir -> Animação Perspectiva_Subir
		anim_name = prefix + "Perspectiva_Subir"
	else:
		# Quer Descer -> Animação Perspectiva_Descer
		anim_name = prefix + "Perspectiva_Descer"
	
	# Verifica se a animação existe (Inseto 1 tem, Inseto 2 não tem)
	if sprite.sprite_frames.has_animation(anim_name):
		# Se TEM a animação: Trava o player e dá play
		is_changing_perspective = true
		sprite.play(anim_name)
		velocity = Vector2.ZERO # Para o movimento para não deslizar
	else:
		# Se NÃO TEM a animação: Troca imediata (lógica antiga)
		execute_climb_switch()

# Chamado automaticamente pelo sinal 'animation_finished' do AnimatedSprite
func _on_animation_finished():
	if is_changing_perspective:
		execute_climb_switch()
		is_changing_perspective = false # Destrava o player

# A lógica real de trocar o booleano 'climbing'
func execute_climb_switch():
	climbing = !climbing
	
	if climbing:
		# Acabou de subir
		pass
	else:
		# Acabou de descer
		sprite.rotation = 0

# ==========================================================
# LÓGICA DA GRADE (TILEMAP)
# ==========================================================
func check_grade_logic():
	var grade_map = get_tree().get_first_node_in_group("layer_grade")
	
	if grade_map:
		var map_pos = grade_map.local_to_map(grade_map.to_local(global_position))
		var tile_data = grade_map.get_cell_tile_data(map_pos)
		
		if tile_data and tile_data.get_custom_data("can_climb"):
			GameController.can_climb = true
		else:
			if not GameController.in_transition_fade:
				GameController.can_climb = false
				
				# Se saiu da grade, força a descida (sem animação de perspectiva, pois caiu)
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
	print("Evoluiu para nível: ", insect_level)
