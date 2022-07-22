extends Node


export var score_label_path: NodePath
var score_label: Label
var final_score: int = 0


func _ready():
  score_label = get_node(score_label_path)
  final_score = GameGlobal.scores
  score_label.text = "Final Scores: " + str(final_score)
  print(final_score)
  GameGlobal.set_scores(0)


func _unhandled_input(event):
  if event is InputEventMouseButton:
    if event.pressed:
      if event.button_index == BUTTON_RIGHT:
        replay_game()
  if event is InputEventKey:
    if event.is_action_pressed("gun_reload"):
      replay_game()


func replay_game() -> void:
  match get_tree().change_scene("res://GameNode.tscn"):
    OK:
      pass
    _:
      print("fail to change scene")
