extends Sprite


onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")


func _ready() -> void:
  anim_player.play("explode")
  anim_player.connect("animation_finished", self, "_on_anim_finished")


func _on_anim_finished(anim_name: String):
  if anim_name == "explode":
    queue_free()
