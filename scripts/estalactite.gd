extends RigidBody2D

@export var is_area: bool
@export var is_killable: bool
@export var distance: int

func _ready():
	gravity_scale = 0
	
	if distance != 0:
		$Area2D.position.y = distance / 2 * 60
		$Area2D/CollisionShape2D.shape.size.y = distance * 60
	$Faiscas.emitting = is_killable

# --- SINAL DO FILHO (Area2D) ---
func _on_area_2d_body_entered(body):
	if !is_area: return
	
	if body.name == "Player":
		gravity_scale = 1
		
		if has_node("Area2D"):
			$Area2D.queue_free()

# --- SINAL DO PAI (RigidBody) ---
func _on_body_entered(body):
	if !is_killable: return
	
	if body.name == "Player":
		GameController.player.dead = true
	
	queue_free()
