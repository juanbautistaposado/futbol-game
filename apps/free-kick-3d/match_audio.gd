extends Node

const EFFECTS := {
	"kick": preload("res://audio/kick.wav"),
	"save": preload("res://audio/save.wav"),
	"post": preload("res://audio/post.wav"),
	"net": preload("res://audio/net.wav"),
}
const CHEER := preload("res://audio/cheer.wav")
const GOAL_VOICE := preload("res://audio/goal_voice.wav")
const CROWD := preload("res://audio/crowd.wav")

var crowd_player: AudioStreamPlayer
var pitch_rng := RandomNumberGenerator.new()

static func ensure_buses() -> void:
	for bus_name in ["Match SFX", "Stadium"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

static func set_global_volume(value: float) -> void:
	ensure_buses()
	var volume := clampf(value, 0.0, 1.0)
	for bus_name in ["Match SFX", "Stadium"]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		AudioServer.set_bus_mute(bus_index, volume <= 0.001)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(volume, 0.001)))

func _ready() -> void:
	ensure_buses()
	pitch_rng.randomize()
	crowd_player = AudioStreamPlayer.new()
	crowd_player.name = "CrowdAmbience"
	var loop: AudioStreamWAV = CROWD.duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	crowd_player.stream = loop
	crowd_player.bus = &"Stadium"
	crowd_player.volume_db = -15.0
	add_child(crowd_player)
	crowd_player.play()

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

func play_goal_cheer() -> void:
	var crowd := AudioStreamPlayer.new()
	crowd.name = "GoalCheer"
	crowd.stream = CHEER
	crowd.bus = &"Stadium"
	crowd.volume_db = -15.0
	add_child(crowd)
	crowd.finished.connect(crowd.queue_free)
	crowd.play()
	var voice := AudioStreamPlayer.new()
	voice.name = "GoalCall"
	voice.stream = GOAL_VOICE
	voice.bus = &"Stadium"
	voice.volume_db = -1.0
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()
