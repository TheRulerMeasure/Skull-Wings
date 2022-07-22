extends Node


var music_source: Resource = load("res://assets/Grey Sector v0_85.mp3")
var music_playing: bool = false


func play_music() -> void:
  music_playing = true
  var music_aud: AudioStreamPlayer = get_node("Music")
  music_aud.stream = music_source
  music_aud.play()
#  print("play music")
