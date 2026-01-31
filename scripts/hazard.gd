extends RigidBody2D

func _ready():
	gravity_scale = 0

# --- SINAL DO FILHO (Area2D) ---
func _on_area_2d_body_entered(body):
	if body.name == "Player":
		gravity_scale = 1
		
		if has_node("Area2D"):
			$Area2D.queue_free()

# --- SINAL DO PAI (RigidBody) ---
func _on_body_entered(body):
	if body.name == "Player":
		pass
		# Dano
	
	queue_free()
