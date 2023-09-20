extends Node3D

const SPEED = 20.0

@onready var mesh = $MeshInstance3D
@onready var RayCast = $RayCast3D
@onready var particles = $GPUParticles3D
@onready var hit_ball_effect = preload("res://sound effects/Hit_ball.wav")
@onready var audio_Stram_player = $AudioStreamPlayer3D


func _ready():
	set_multiplayer_authority(name.to_int())
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	position += transform.basis * Vector3(0,0,-SPEED) * delta

	if RayCast.is_colliding():
		particles.emitting = true
		#play_effect(hit_ball_effect)
		audio_Stram_player.play()
		mesh.hide()
		await get_tree().create_timer(1.0).timeout
		queue_free()


func _on_timer_timeout():
	queue_free()


func play_effect(effect: AudioStream): #must be audio type
	var player = AudioStreamPlayer.new();
	add_child(player)
	print("sound fx should be playing")
	#if !player.playing:
	player.stream = effect;
	player.play()
	await get_tree().create_timer(1).timeout
	remove_child(player)
