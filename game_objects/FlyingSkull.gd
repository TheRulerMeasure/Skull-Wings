extends Area2D


signal attacked

export var approach_speed: float = 30.0
export var start_distace: float = 270.0
var distance: float
#var is_alive: bool = true
onready var _tween: Tween = $Tween
onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")


func _ready() -> void:
  distance = start_distace


func _process(delta: float) -> void:
#  if not is_alive:
#    return

  anim_player.play("fly")
  if distance <= 0:
    return

  distance -= approach_speed * delta
  var skull_scale: float = clamp((250-distance)*0.02, 0.1, 20)
  scale = Vector2(skull_scale, skull_scale)

  if distance < 0:
    distance = 0
    if not _tween.is_active():
      start_attack()

  z_index = int(250-distance)


func start_attack() -> void:
  _tween.interpolate_property(
    self,
    "position",
    position,
    get_viewport_rect().size/2,
    0.5,
    Tween.TRANS_LINEAR
  )
  _tween.interpolate_property(
    self,
    "scale",
    scale,
    scale+Vector2(10, 10),
    0.5,
    Tween.TRANS_LINEAR
  )
  _tween.start()
  if _tween.connect("tween_completed", self, "attack") != OK:
    print("connect fail")


func clean_self(anim_name: String) -> void:
  if anim_name == "death":
    queue_free()


func damage() -> void:
  set_process(false)
  var col: CollisionShape2D = get_node("FlyingSkullCol")
  col.set_deferred("disabled", true)
  _tween.stop_all()
  anim_player.play("death")
  anim_player.connect("animation_finished", self, "clean_self")


func attack(obj: Object, key: NodePath) -> void:
  if (obj == self and key == NodePath("position").get_as_property_path()):
    emit_signal("attacked")
    print("attacked")
    queue_free()
