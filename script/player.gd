extends CharacterBody3D
 
signal health_changed(health_value)
signal death_counter(deaths)

@onready var camera = $Camera3D
@onready var view_camera = $Camera3D/Camera3D
@export var seny := 0.005
@export var senx := 0.005 
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



var friction: float = 4
var accel: float = 10

# 4 for quake 2/3 40 for quake 1/source
var accel_air: float = 4
var top_speed_ground: float = 10
# 15 for quake 2/3, 2.5 for quake 1/source
var top_speed_air: float = 7
# linearize friction below this speed value
var lin_friction_speed: float = 5
var jump_force: float = 9
var projected_speed: float = 0
var grounded_prev: bool = true
var grounded: bool = true
var wish_dir: Vector3 = Vector3.ZERO



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
		


func clip_velocity(normal: Vector3, overbounce: float, _delta) -> void:
	var correction_amount: float = 0
	var correction_dir: Vector3 = Vector3.ZERO
	var move_vector: Vector3 = get_velocity().normalized()
	
	correction_amount = move_vector.dot(normal) * overbounce
	
	correction_dir = normal * correction_amount
	velocity -= correction_dir
	# this is only here cause I have the gravity too high by default
	# with a gravity so high, I use this to account for it and allow surfing
	velocity.y -= correction_dir.y * (gravity/20)

func apply_friction(delta):
	var speed_scalar: float = 0
	var friction_curve: float = 0
	var speed_loss: float = 0
	var current_speed: float = 0
	
	# using projected velocity will lead to no friction being applied in certain scenarios
	# like if wish_dir is perpendicular
	# if wish_dir is obtuse from movement it would create negative friction and fling players
	current_speed = velocity.length()
	
	if(current_speed < 0.1):
		velocity.x = 0
		velocity.y = 0
		return
	
	friction_curve = clampf(current_speed, lin_friction_speed, INF)
	speed_loss = friction_curve * friction * delta
	speed_scalar = clampf(current_speed - speed_loss, 0, INF)
	speed_scalar /= clampf(current_speed, 1, INF)
	
	velocity *= speed_scalar

func apply_acceleration(acceleration: float, top_speed: float, delta):
	var speed_remaining: float = 0
	var accel_final: float = 0
	
	speed_remaining = (top_speed * wish_dir.length()) - projected_speed
	
	if speed_remaining <= 0:
		return
	
	accel_final = acceleration * delta * top_speed
	
	clampf(accel_final, 0, speed_remaining)
	
	velocity.x += accel_final * wish_dir.x
	velocity.z += accel_final * wish_dir.z

func air_move(delta):
	apply_acceleration(accel_air, top_speed_air, delta)
	
	clip_velocity(get_wall_normal(), 14, delta)
	clip_velocity(get_floor_normal(), 14, delta)
	
	velocity.y -= gravity * delta

func ground_move(delta):
	floor_snap_length = 0.4
	apply_acceleration(accel, top_speed_ground, delta)
	
	if Input.is_action_pressed("jump"):
		velocity.y = jump_force
		play_effect(jump_effect)
	
	if grounded == grounded_prev:
		apply_friction(delta)
	
	if is_on_wall:
		clip_velocity(get_wall_normal(), 1, delta)


func _physics_process(delta):
	# Add the gravity.
	if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("throw") and is_on_floor() \
		and animation_player.current_animation != "Lancio":
			throw_ball.rpc()
			
	if Input.is_action_just_pressed("super"):
		superThrow()
	
	grounded_prev = grounded
	# Get the input direction and handle the movement/deceleration.
	var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	wish_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	projected_speed = (velocity * Vector3(1, 0, 1)).dot(wish_dir)
	
	
	
	
	# Add the gravity.
	if not is_on_floor():
		grounded = false
		air_move(delta)
	if is_on_floor():
		if velocity.y > 10:
			grounded = false
			air_move(delta)
		else:
			grounded = true
			ground_move(delta)
	
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
	

#music gets heard twice
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
	
#@rpc("call_local")
func superThrow():
	if is_super_charged:
		is_super_charged = false
		throw_ball.rpc()
		await get_tree().create_timer(0.5).timeout
		throw_ball.rpc()
		await get_tree().create_timer(0.5).timeout
		throw_ball.rpc()
		super_timer.start()




func _on_audio_timer_timeout():
	play_music()


func _on_hitbox_area_entered(area):
	if area.is_in_group("ball"):
		recive_damage()


func _on_super_timer_timeout():
	is_super_charged = true
