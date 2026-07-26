extends EnemyState
class_name EnemyStateMoving



func _enter_tree() -> void:
	enemy.animation_player.play("idle")
