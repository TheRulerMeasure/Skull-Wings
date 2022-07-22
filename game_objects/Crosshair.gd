extends Node2D


enum DiceFace {
  ONE = 0,
  TWO = 1,
  THREE = 3,
  FOUR = 4,
  FIVE = 5,
  SIX = 2,
}

signal fired(shell)
signal dry_fired
signal no_ammo
signal reloaded(shell)
signal killed(target)
signal loaded_shell(face)
signal health_depleted(health)
signal gun_ready(is_ready)

export var start_clip_size: int = 5
export var max_clip_size: int = 6
export var shell_count_path: NodePath
export var shell_sprite_packed: PackedScene
export var shell_count_padding: float = 75.0
export var shot_explosion_effect_packed: PackedScene
var shells: Array = []
var targets: Array = []
var rand: RandomNumberGenerator = RandomNumberGenerator.new()
var reloading: bool = false
var shell_count: MarginContainer
var shell_sprites: Node2D
var health: int = 6
onready var shoot_timer: Timer = get_node("ShootTimer")
onready var reload_timer: Timer = get_node("ReloadTimer")
onready var collusion_group = [
  [
    $HitArea/OneAreaCol,
  ],
  [
    $HitArea/TwoAreaCol1,
    $HitArea/TwoAreaCol2,
  ],
  [
    $HitArea/ThreeAreaCol1,
    $HitArea/ThreeAreaCol2,
    $HitArea/ThreeAreaCol3,
  ],
  [
    $HitArea/FourAreaCol1,
    $HitArea/FourAreaCol2,
    $HitArea/FourAreaCol3,
    $HitArea/FourAreaCol4,
  ],
  [
    $HitArea/FiveAreaCol1,
    $HitArea/FiveAreaCol2,
    $HitArea/FiveAreaCol3,
    $HitArea/FiveAreaCol4,
    $HitArea/FiveAreaCol5,
  ],
  [
    $HitArea/SixAreaCol1,
    $HitArea/SixAreaCol2,
    $HitArea/SixAreaCol3,
    $HitArea/SixAreaCol4,
    $HitArea/SixAreaCol5,
    $HitArea/SixAreaCol6,
  ],
]
onready var reload_progress: TextureProgress = get_node("TextureProgress")
onready var shoot_sound: AudioStreamPlayer = get_node("shotgun_shoot_sound")
onready var cock_sound: AudioStreamPlayer = get_node("shotgun_cock_sound")
onready var load_sound: AudioStreamPlayer = get_node("shotgun_load_sound")
onready var hurt_sound: AudioStreamPlayer = get_node("hurt_sound")
onready var enemy_die_sound: AudioStreamPlayer = get_node("enemy_die_sound")


func _ready() -> void:
  shell_count = get_node(shell_count_path)
  shell_sprites = shell_count.get_node("ShellSprites")

  rand.randomize()

  for i in collusion_group:
    for j in i:
      j.set_deferred("disabled", true)
      j.get_node("Sprite").visible = false

  for i in range(start_clip_size):
    var face_num = rand.randi_range(0, 5)
    shells.append(face_num)
    var shell_sprite: Sprite = shell_sprite_packed.instance()
    shell_sprite.position = shell_x_pos_of(i)
    shell_sprite.frame = convert_to_dice_face(face_num)
    shell_sprites.add_child(shell_sprite)

  enable_group(shells[0])
  emit_signal("gun_ready", true)
#  print(shells)

  if shoot_timer.connect("timeout", self, "shoot_delay_ended") != OK:
    print("connect failed")
  if reload_timer.connect("timeout", self, "shell_loaded") != OK:
    print("connect failed")


func _process(_delta: float) -> void:
  position = get_global_mouse_position()
  if reload_timer.time_left > 0:
    var p: float = (reload_timer.time_left/reload_timer.get_wait_time()) * 100
    reload_progress.value = p
    return
  reload_progress.value = 0.0


func _unhandled_input(event) -> void:
  if event is InputEventMouseButton:
    if event.pressed:
      if event.button_index == BUTTON_LEFT:
        if shoot_timer.time_left > 0:
          print("delaying, no shot")
          return
        if reloading:
          interrupt_reload()
          return
        fired()
      if event.button_index == BUTTON_RIGHT:
        if reloading:
          return
        gun_reload()
    return
  if event is InputEventKey:
    if event.is_action_pressed("gun_reload"):
      if reloading:
        return
      gun_reload()


func set_health(new_health: int, is_attack: bool = true) -> int:
  health = new_health
  if is_attack:
    emit_signal("health_depleted", health)
    hurt_sound.play()
  return health


func get_health() -> int:
  return health


func convert_to_dice_face(face_num: int) -> int:
  match face_num:
    0:
      return DiceFace.ONE
    1:
      return DiceFace.TWO
    2:
      return DiceFace.THREE
    3:
      return DiceFace.FOUR
    4:
      return DiceFace.FIVE
    _:
      return DiceFace.SIX


func shell_x_pos_of(index: int) -> Vector2:
  return Vector2(
    (index*shell_count_padding),
    0
  )


func interrupt_reload() -> void:
  reload_timer.stop()
  reloading = false
  if not shells.empty():
    enable_group(shells[0])
    emit_signal("gun_ready", true)


func gun_reload() -> void:
  if shells.size() >= max_clip_size:
    return
  reloading = true
  emit_signal("gun_ready", false)
  reload_timer.start()


func eject_chamber_shell(shell_array: Array) -> void:
  if shell_array.empty():
    return
  shell_array.pop_front()
  shell_sprites.get_child(0).queue_free()
  reposition_shell_sprites()
  print(shell_array)


func explosion_effect(face: int) -> void:
  var sprite_scale: Vector2 = Vector2(5.0, 5.0)
  if face == 0:
    sprite_scale *= 2

  for i in collusion_group[face]:
    var explosion_sp: Sprite = shot_explosion_effect_packed.instance()
    explosion_sp.position = i.global_position
    explosion_sp.scale = sprite_scale
    get_parent().add_child(explosion_sp)


func fired() -> void:
  if shells.empty():
    emit_signal("dry_fired")
    print("no shell left")
    return

  disable_group(shells[0])
  explosion_effect(shells[0])
  emit_signal("fired", shells[0])
  shoot_sound.play()
  cock_sound.play()

  eject_chamber_shell(shells)
  shoot_timer.start()

  if targets.empty():
    return

  emit_signal("killed", targets)
  for i in targets:
    i.call("damage")
  enemy_die_sound.play()


func reposition_shell_sprites() -> void:
  for i in range(shell_sprites.get_children().size()):
    var sp: Sprite = shell_sprites.get_child(i)
    sp.position = shell_x_pos_of(i-1)


func shell_loaded() -> void:
  if shells.size() >= max_clip_size:
    reloading = false
    if not shells.empty():
      enable_group(shells[0])
      emit_signal("gun_ready", true)
    return
  var face: int = rand.randi_range(0, 5)
  shells.append(face)
  emit_signal("loaded_shell", face)
  reload_timer.start()
  var shell_sprite: Sprite = shell_sprite_packed.instance()
  shell_sprite.position = shell_x_pos_of(shells.size()-1)
  shell_sprite.frame = convert_to_dice_face(face)
  shell_sprites.add_child(shell_sprite)
  load_sound.play()
#  print(shells)


func shoot_delay_ended() -> void:
  if shells.empty():
    emit_signal("no_ammo")
    return
  enable_group(shells[0])
  emit_signal("gun_ready", true)
  emit_signal("reloaded", shells[0])


func enable_group(face_enum: int) -> void:
  for i in collusion_group[face_enum]:
    i.set_deferred("disabled", false)
    i.get_node("Sprite").visible = true


func disable_group(face_enum: int) -> void:
  for i in collusion_group[face_enum]:
    i.set_deferred("disabled", true)
    i.get_node("Sprite").visible = false


func _on_HitArea_area_entered(area) -> void:
  if area is Area2D:
    if area.is_in_group("enemy"):
      targets.append(area)
#      print(targets)


func _on_HitArea_area_exited(area) -> void:
  if area is Area2D:
    if area.is_in_group("enemy"):
      if area in targets:
        targets.remove(targets.find(area))
#        print(targets)
