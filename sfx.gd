extends Node

# ============================================================
#  SFX MANAGER (Autoload)
# ============================================================
#  Usage: SFX.play("hit")
#  Add new sounds by putting .wav files in res://assets/sfx/
#  and adding them to the SOUNDS dictionary below.

var players = {}

const SOUNDS = {
	"hit": "res://assets/sfx/hitHurt.wav",
	"miss": "res://assets/sfx/miss.wav",
}

const MAX_PLAYERS := 8  # max simultaneous sounds


func _ready():
	# Pre-load all sounds
	for key in SOUNDS:
		var stream = load(SOUNDS[key])
		if stream:
			players[key] = stream


func play(sound_name: String, volume_db: float = 0.0):
	if not players.has(sound_name):
		return

	var player = AudioStreamPlayer.new()
	player.stream = players[sound_name]
	player.volume_db = volume_db
	add_child(player)
	player.play()

	# Clean up after finished
	player.finished.connect(player.queue_free)
