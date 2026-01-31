extends Node

var checkpoint_position = null
var has_checkpoint = false

func set_checkpoint(pos):
	checkpoint_position = pos
	has_checkpoint = true

func set_default_checkpoint(pos):
	if has_checkpoint == false:
		checkpoint_position = pos
		has_checkpoint = true

func reload_scene():
	get_tree().reload_current_scene()

func respawn_player(player):
	if has_checkpoint:
		player.global_position = checkpoint_position
