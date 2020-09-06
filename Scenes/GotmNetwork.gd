extends Node

signal connected

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var ticker = 0
var lobby
var players = {}
var peer
var tick_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    print("My ID is: " + str(Gotm.user.id))
    print("My name is: " + str(Gotm.user.display_name))


func connect_to_lobby():
    print("In Pull Lobby")
    var fetch = GotmLobbyFetch.new()
    print("Fetched")
    var lobbies = yield(fetch.first(), "completed")
    print("Got past 'fetch'")
    print("Lobbies: " + str(lobbies))
    if not lobbies:
        print("Lobby Not Found")
        create_new_lobby()
        print("Now there's a lobby")
        emit_signal("connected")
        return true
    print("Lobby Found")
    lobby = lobbies[0]
    print("Lobby is: " + str(lobby))
    var success = yield(lobby.join(), "completed")
    print("tried to join lobby")
    print("Lobby Joined: " + str(success))
    peer = NetworkedMultiplayerENet.new()
    print("Host Address: " + str(Gotm.lobby.host.address))
    peer.create_client(Gotm.lobby.host.address, 8070)
    get_tree().set_network_peer(peer)
    print("Client created")
    emit_signal("connected")
    return true

func create_new_lobby():
    print("Creating Lobby")
    Gotm.host_lobby(false)
    print("Hosting Library")
    lobby = Gotm.lobby
    Gotm.lobby.name("PressToSave")
    print("Setting name")
    print("Lobby hidden state: " + str(Gotm.lobby.hidden))
    Gotm.lobby.hidden = false
    print("Created Lobby")
    peer = NetworkedMultiplayerENet.new()
    peer.create_server(8070, 100)
    get_tree().set_network_peer(peer)
    print("Server created")
    return true
    
    

