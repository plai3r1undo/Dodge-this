extends Node3D

@onready var main_menu = $CanvasLayer/MainMenu


var ip_address := "localhost"
const   PLAYER = preload("res://scenes/player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new( )


func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _unhandled_input(event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_address_text_submitted(new_text):
	ip_address = new_text


func _on_host_pressed():
	main_menu.hide()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	
	add_player(multiplayer.get_unique_id()) 


func _on_join_pressed():
	main_menu.hide()
	enet_peer.create_client(ip_address, PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	
func add_player(peer_id):
	var PLAYER = PLAYER.instantiate()
	PLAYER.name = str(peer_id)
	add_child(PLAYER)
	
	
	
	
	
	
	
	
	
	
