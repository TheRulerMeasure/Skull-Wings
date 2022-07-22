extends Sprite


onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")


func _on_fired(_shell: int):
  anim_player.play("shoot")


func _on_gun_ready(is_ready: bool):
  if is_ready:
    anim_player.play("idle")
    return

  anim_player.play("reload")
