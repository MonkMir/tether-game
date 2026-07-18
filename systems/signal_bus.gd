extends Node

# GAME OVER

signal game_over()

# PARTICLES

signal player_hit(position: Vector2, attacker_position: Vector2)
signal enemy_hit(position: Vector2, attacker_position: Vector2)
