extends Node


const DIE_FACE: Array = [
  [
    Vector2.ZERO
  ],
  [
    Vector2(-110, -110),
    Vector2(110, 110),
  ],
  [
    Vector2(-110, -110),
    Vector2.ZERO,
    Vector2(110, 110),
  ],
  [
    Vector2(-110, -110),
    Vector2(-110, 110),
    Vector2(110, -110),
    Vector2(110, 110),
  ],
  [
    Vector2.ZERO,
    Vector2(-110, -110),
    Vector2(-110, 110),
    Vector2(110, -110),
    Vector2(110, 110),
  ],
  [
    Vector2(-105, 0),
    Vector2(105, 0),
    Vector2(-110, -110),
    Vector2(-110, 110),
    Vector2(110, -110),
    Vector2(110, 110),
  ],
]

export var allow_spawner: bool = true
export var crosshair_path: NodePath
export var flying_skull_packed: PackedScene
export var hp_bar_path: NodePath
export var shotgun_path: NodePath
export var score_label_path: NodePath
var rand: RandomNumberGenerator = RandomNumberGenerator.new()
var crosshair: Node2D
var min_spawn_freq: float = 0.15
var max_spawn_freq: float = 3.0
var cur_spawn_freq: float = 8.0
var freq_decrease_rate: float = 0.3
var in_combo: bool = false
var hp_bar: TextureProgress
var shotgun: Sprite
var score_label: Label
onready var enemies: Node2D = get_node("GameNode2D/Enemies")
onready var spawn_timer: Timer = get_node("SpawnTimer")


func _ready() -> void:
  rand.randomize()
  crosshair = get_node(crosshair_path)
  if crosshair.connect("health_depleted", self, "check_player_health") != OK:
    print("connect failed")
  if crosshair.connect("killed", self, "add_score") != OK:
    print("connect failed")
  spawn_timer.start(1)
  hp_bar = get_node(hp_bar_path)
  hp_bar.value = crosshair.call("get_health")
  shotgun = get_node(shotgun_path)

  score_label = get_node(score_label_path)

  crosshair.connect("fired", shotgun, "_on_fired")
  crosshair.connect("gun_ready", shotgun, "_on_gun_ready")

  if GameMusic.music_playing:
    return
  GameMusic.play_music()


func spawn_skull_at(pos: Vector2) -> void:
  var flying_skull: Area2D = flying_skull_packed.instance()
  flying_skull.position = pos
  enemies.add_child(flying_skull)
  if flying_skull.connect("attacked", self, "skull_attacked_player") != OK:
    print("connect failed")


func skull_attacked_player():
  crosshair.call("set_health", crosshair.call("get_health") - 1)


func spawn_in_die(face: int, pos: Vector2) -> void:
  in_combo = true

  for i in DIE_FACE[face]:
    spawn_timer.start(0.1)
    yield(spawn_timer, "timeout")
    spawn_skull_at(pos+i)

  in_combo = false
  spawn_timer.start(
    rand.randf_range(
      min_spawn_freq + cur_spawn_freq,
      max_spawn_freq + cur_spawn_freq
    )
  )
  cur_spawn_freq = lerp(cur_spawn_freq, 0, freq_decrease_rate)


func change_to_game_end() -> void:
  if get_tree().change_scene("res://GameEndNode.tscn") != OK:
    print("cannot change scene")


func check_player_health(health: int) -> void:
  if health <= 0:
    change_to_game_end()
    return
  hp_bar.value = health


func add_score(targets: Array) -> void:
  var scores: int = GameGlobal.set_scores(GameGlobal.scores + targets.size())
  score_label.text = "Scores: " + str(scores)


func _on_SpawnTimer_timeout() -> void:
  if not allow_spawner or in_combo:
    return

  var game_node2d: Position2D = get_node("GameNode2D").get_node("SpawnRect")
  var viewport_pos: Vector2 = game_node2d.position
  var viewport_size: Position2D = game_node2d.get_node("RectSize")
  var spawn_at: Vector2 = Vector2(
    rand.randf_range(viewport_pos.x, viewport_size.global_position.x),
    rand.randf_range(viewport_pos.y, viewport_size.global_position.y)
  )

  if rand.randf() > 0.5:
    spawn_in_die(rand.randi_range(0, 5), spawn_at)
    return

  spawn_skull_at(
    spawn_at
  )

  spawn_timer.start(
    rand.randf_range(
      min_spawn_freq + cur_spawn_freq,
      max_spawn_freq + cur_spawn_freq
    )
  )

  cur_spawn_freq = lerp(cur_spawn_freq, 0, freq_decrease_rate)


func _on_Crosshair_fired(shell):
  pass # Replace with function body.


func _on_Crosshair_dry_fired():
  pass # Replace with function body.
