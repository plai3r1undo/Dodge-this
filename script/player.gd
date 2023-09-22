extends CharacterBody3D
 
signal health_changed(health_value)
signal death_counter(deaths)

const SPEED = 8
const JUMP_VELOCITY = 9.0

@onready var camera = $Camera3D
@onready var view_camera = $Camera3D/Camera3D
@export var seny := 0.005
@export var senx := 0.005
@export var super_wait_time: float = 0.5 #this is the time between each ball in the super, to change the timer beteen each super change
										#in the timer node
@onready var animation_player =  $prova_personaggio/AnimationPlayer
@onready var RayCast = $Camera3D/Camera3D/Node3D/RayCast3D
@onready var jump_effect: AudioStream = preload("res://sound effects/Jump.wav")
@onready var ball_throw_effect: AudioStream = preload("res://sound effects/Ball_throw_sound.wav")
@onready var death_effect: AudioStream = preload("res://sound effects/hit.wav")
@onready var audio_stram_player = $AudioStreamPlayer
@onready var label_name = $Label3D
var death: int = 0;
var is_super_charged: bool = true
@onready var super_timer: Timer = $superTimer
var player_name := "name";


@export var health: int = 10

@export var kill_counter: int = 0

var ball = load("res://scenes/ball.tscn")
var instance #sort of buffer maybe ??

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

	
func _enter_tree():
	set_multiplayer_authority(str(name).to_int())


func _ready():
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	view_camera.current = true
	var main_scene = get_tree().get_root().get_node("/root/mapDemo")
	main_scene.name_changed.connect(update_player_name)
	label_name.text = player_name;
	label_name.show()
	main_scene.high_pixel_resolution.connect(change_pixel_resolution)
	"""
	In the future needs to be calle when a match starts
	"""
 
func change_pixel_resolution(high_res):
	var shader_mesh = $Camera3D/Camera3D/Node3D/MeshInstance3D
	if high_res:
		shader_mesh.set_instance_shader_parameter("pixel_size",2)
		print("high res has been set!")
	else:
		shader_mesh.set_instance_shader_parameter("pixel_size",6)
		print("low res has been set!!!!!")

func update_player_name(name_player):
	label_name = name_player
	print("name changed")


func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * senx * .2)
		camera.rotate_x(-event.relative.y * seny * .2)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
 
func _process(_delta):
	handle_volume()
	
	if  Input.is_action_just_pressed("respawn"):
		position = Vector3(0,5,0)
		
	if Input.is_action_pressed("super"):
		superThrow();
	

func _physics_process(delta):
	# Add the gravity.
	if not is_multiplayer_authority(): return
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		play_effect(jump_effect)
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("throw") and is_on_floor() \
		and animation_player.current_animation != "Lancio":
			throw_ball.rpc()



	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if animation_player.current_animation == "Lancio":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		animation_player.play("idle",-1,2)
	else:
		animation_player.play("idle")
	move_and_slide()




@rpc("call_local")
func throw_ball():
	animation_player.stop()
	animation_player.play("Lancio",-1,3.0)
	instance = ball.instantiate()
	play_effect(ball_throw_effect);
	instance.position = RayCast.global_position
	instance.transform.basis = RayCast.global_transform.basis
	get_parent().add_child(instance)
	

#music gets herad twice
func play_music():
	if audio_stram_player.is_playing():
		pass
	else:
		audio_stram_player.play()
		

func handle_volume():
	var volume = AudioServer.get_bus_volume_db(0)
	if Input.is_action_just_pressed("increase_volume"):
		AudioServer.set_bus_volume_db(0,volume + 1)
		print("increasing volume")
	if Input.is_action_just_pressed("lower_volume"):
		AudioServer.set_bus_volume_db(0,volume - 1)



func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Lancio":
		animation_player.play("idle")



func play_effect(effect: AudioStream): #must be audio type
	var player = AudioStreamPlayer.new();
	add_child(player)
	#if !player.playing:
	player.stream = effect;
	player.play()
	await get_tree().create_timer(1).timeout
	remove_child(player)

@rpc("any_peer")
func recive_damage():
	health -= 2;
	if health <= 0:
		position = Vector3(0,5,0)
		health = 10;
		death += 1;
		play_effect(death_effect);
		death_counter.emit(death);
	health_changed.emit(health)
	

func superThrow():
	if is_super_charged:
		is_super_charged = false
		super_timer.start()
		throw_ball.rpc()
		await get_tree().create_timer(0.5).timeout
		throw_ball.rpc()
		await get_tree().create_timer(0.5).timeout
		throw_ball.rpc()



func _on_audio_timer_timeout():
	play_music()


func _on_hitbox_area_entered(area):
	if area.is_in_group("ball"):
		recive_damage()


func _on_super_timer_timeout():
	is_super_charged = true
