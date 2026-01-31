extends Area2D

@export var target_hazard_ids: Array[String] = ["A"]  # coloque quantos quiser
var fired = false

func _ready():
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if fired:
		return
	if body.name != "Player":
		return

	fired = true

	for id in target_hazard_ids:
		get_tree().call_group("hazard_" + id, "activate")

	queue_free() # se quiser que dispare só uma vez
