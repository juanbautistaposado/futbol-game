extends Node

const EFFECTS := {
	"kick": preload("res://audio/kick.wav"),
	"save": preload("res://audio/save.wav"),
	"post": preload("res://audio/post.wav"),
	"net": preload("res://audio/net.wav"),
}
const GOAL_SIGNAL := preload("res://audio/goal.wav")
const MISS_SIGNAL := preload("res://audio/miss.wav")

var result_player: AudioStreamPlayer
var pitch_rng := RandomNumberGenerator.new()

static func ensure_buses() -> void:
	for bus_name in ["Match SFX", "Results"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

static func set_global_volume(value: float) -> void:
	ensure_buses()
	var volume := clampf(value, 0.0, 1.0)
	for bus_name in ["Match SFX", "Results"]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		AudioServer.set_bus_mute(bus_index, volume <= 0.001)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(volume, 0.001)))

func _ready() -> void:
	ensure_buses()
	pitch_rng.randomize()
	result_player = AudioStreamPlayer.new()
	result_player.name = "ShotResult"
	result_player.bus = &"Results"
	result_player.volume_db = -6.0
	add_child(result_player)

func play_effect(kind: String, position_3d: Vector3) -> void:
	if not EFFECTS.has(kind):
		return
	var player := AudioStreamPlayer3D.new()
	player.name = "Sound_%s" % kind
	player.stream = EFFECTS[kind]
	player.bus = &"Match SFX"
	player.volume_db = -3.0
	player.unit_size = 18.0
	player.max_distance = 120.0
	player.pitch_scale = pitch_rng.randf_range(0.96, 1.04)
	add_child(player)
	player.global_position = position_3d
	player.finished.connect(player.queue_free)
	player.play()

func play_result(scored: bool) -> void:
	result_player.stop()
	result_player.stream = GOAL_SIGNAL if scored else MISS_SIGNAL
	result_player.play()
