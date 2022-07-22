extends Control


func _unhandled_input(event):
  if event is InputEventMouseButton:
    if event.pressed:
      if event.button_index == BUTTON_LEFT:
        get_tree().change_scene("res://GameNode.tscn")
