extends Node3D




signal name_changed(name)
signal high_pixel_resolution(high_pixel_resolution)

@onready var main_menu = $CanvasLayer/MainMenu


var ip_address := "localhost"
const PLAYER = preload("res://scenes/player.tscn")
var PORT: int = 9999
var enet_peer = ENetMultiplayerPeer.new( )
@onready var hud = $CanvasLayer/HUD 
@onready var health_bar = $CanvasLayer/HUD/TextureProgressBar
@onready var death_counter: Label = $CanvasLayer/HUD/death
@onready var back_ground: ColorRect = $CanvasLayer/ColorRect
@onready var title: VBoxContainer = $CanvasLayer/Title
var high_pixel_form = false;




func _ready():
	hud.hide()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass



func _unhandled_input(_event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_address_text_submitted(new_text):
	ip_address = new_text


func _on_host_pressed():
	main_menu.hide()

	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player(multiplayer.get_unique_id())
	hud.show()
	back_ground.hide()
	title.hide()

func _on_join_pressed():
	main_menu.hide()
	enet_peer.create_client(ip_address, PORT)
	multiplayer.multiplayer_peer = enet_peer
	hud.show()
	back_ground.hide()
	title.hide()

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	
  

func add_player(peer_id):
	@warning_ignore("shadowed_variable")
	var PLAYER = PLAYER.instantiate()
	PLAYER.name = str(peer_id)
	add_child(PLAYER)
	PLAYER.health_changed.connect(update_health_bar)
	if PLAYER.is_multiplayer_authority():
		PLAYER.death_counter.connect(update_death_counter)

func update_health_bar(health_value):
	health_bar.value = health_value 

func update_death_counter(death):
	print("update death counder called" + str(death))
	var deth_text = "		Death: " + str(death)
	death_counter.text = deth_text

func _on_multiplayer_spawner_spawned(node): #must check if it is player if we add more object to mutliplyer Spawner
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)
		node.death_counter.connect(update_death_counter)
		high_pixel_resolution.emit(high_pixel_form)


func _on_name_text_submitted(new_text):
	var allowed_chars =  ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ]
	var player_name: String
	for letter in allowed_chars:
		if new_text.find(letter) == -1:
			player_name = "this gay put invalid charachters"
			return
	player_name = new_text
	name_changed.emit(player_name)
			
	

func _on_check_button_2_toggled(button_pressed):
	high_pixel_form = button_pressed


func _on_upnp_pressed():
	var upnp = UPNP.new()
	var discor_result = upnp.discover()


	if discor_result == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			var map_result_udp = upnp.add_port_mapping(PORT,PORT,"dodge_this_udp", "UDP",0)
			var map_result_tcp = upnp.add_port_mapping(PORT,PORT,"dodge_this_tcp", "TCP",0)
			
			if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(9999,9999,"","UDP");  #some routes don't accept names and some do
			if not map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(9999,9999,"","TCP")
	var external_ip = upnp.query_external_address()
	$CanvasLayer/MainMenu/Label.text = external_ip;


func _on_spin_box_value_changed(value):
	PORT = value;
	print("port: " + str(value))
