extends Control

signal connect_lobby(lobby)
var connecting = true
var private_key = "92afbf2d51af6014e5dd41f769371f1a"
var game_id = "513208"
var user_scores = {}
var user_names = {}
var key_queue = []
var started = false
var peer = null
var clearing = true
var ping_waiting = false
var bad_lobbies = []

func _ready():
    print("_ready")
    $GameJoltAPI.init(private_key, game_id)
    if Gotm.is_live():
        Gotm.connect("lobby_changed", self, "_on_lobby_changed")
        lobby_connect()
    else:
        Gotm.user.id = "X0"
        Gotm.user.display_name = "Zdiles"
        key_queue = ["DefenceSystem"]
        $GameJoltAPI.fetch_data("DefenceSystem")

remote func join_lobby(new_lobby):
    print("join_lobby " + str(new_lobby))
    var success = yield(new_lobby.join(), "completed")
    var peer = NetworkedMultiplayerENet.new()
    peer.create_client(Gotm.lobby.host.address, 8070)  
    get_tree().set_network_peer(peer)

func lobby_connect():
    print("lobby_connect")
    var fetch = GotmLobbyFetch.new()
    var lobbies = yield(fetch.first(5), "completed")
    var lobbies_good = []
    print("  Checking Lobbies(%s):" % str(len(lobbies)))
    for lobby in lobbies:
        print("    - lobby id:" + str(lobby.id))
        print("    lobby peers: " + str(lobby.peers))
        print("    lobby host id: " + str(lobby.host.id))
        print("    lobby host name: " + str(lobby.host.display_name))
        if not(lobby.id in bad_lobbies):
            lobbies_good.append(lobby)
    print("  Creating/choosing lobby.")
    if lobbies_good:
        var lobby = lobbies_good[0]
        print("    lobby id:" + str(lobby.id))
        print("    lobby peers: " + str(lobby.peers))
        print("    lobby host id: " + str(lobby.host.id))
        print("    lobby host name: " + str(lobby.host.display_name))
        var success = yield(lobby.join(), "completed")
        peer = NetworkedMultiplayerENet.new()
        peer.create_client(Gotm.lobby.host.address, 8070)  
        print("    Joined lobby")
    else:
        print("    Hosting")
        Gotm.host_lobby(false)
        Gotm.lobby.name = str(OS.get_system_time_msecs())
        Gotm.lobby.hidden = false
        peer = NetworkedMultiplayerENet.new()
        peer.create_server(8070)
        print("    Lobby id: " + str(Gotm.lobby.id))
    get_tree().set_network_peer(peer)

func _on_lobby_changed():
    print("_on_lobby_changed")
    if Gotm.lobby:
        print("  In Lobby: " + str(Gotm.lobby.id))
        get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
        get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
        print("  Connected network peer calls")
        if Gotm.lobby.is_host():
            print("  Is Host")
            Gotm.lobby.set_property("created", OS.get_system_time_msecs())
        $HostCheckTimer.start()
        connecting = false
    else:
        print("  Not In Lobby")
        $HostCheckTimer.stop()
        lobby_connect()
        print('emit_signal("connect_lobby", null)')
        emit_signal("connect_lobby", null)
        
func _on_network_peer_connected(peer):
    print("_on_network_peer_connected, peer: %s" % peer)
    if not Gotm.lobby.is_host():
        request_update()
    else:
        send_update(false)
    
func _on_network_peer_disconnected(peer):
    print("_on_network_peer_disconnected, peer: %s" % peer)
    if not Gotm.lobby.is_host():
        request_update()
    else:
        send_update(false)

func set_reward(reward_value):
    print("set_reward " + str(reward_value))
    $YourReward/YourReward.add_reward(reward_value)
    $GameJoltAPI.set_data(Gotm.user.id, '["%s",%s]' % [Gotm.user.display_name, $YourReward/YourReward.reward])
    $Benefactors/Benefactors.rewards[Gotm.user.id] = [Gotm.user.display_name, $YourReward/YourReward.reward]
    $Benefactors/Benefactors.update_board()

func _on_ShieldButton_button_down():
    print("_on_ShieldButton_button_down")
    if not $DefenceSystem.state_machine.current_state in ['charging', 'connecting']:
        announce_press()
        $Ticker.active = true
        if Gotm.user.id == "":
            $DefenceSystem.stored_reward = $OfferedReward/CurrentReward.get_prize_value()
            $DefenceSystem.state_machine.transition('charging')
            $GameJoltAPI.set_data("DefenceSystem", $DefenceSystem.get_state_string())
        else:
            set_reward($OfferedReward/CurrentReward.get_prize_value())
            $DefenceSystem.stored_reward = 0
            $DefenceSystem.state_machine.transition('charging')
            $GameJoltAPI.set_data("DefenceSystem", $DefenceSystem.get_state_string())
        send_update(true)

func announce_press():
    print("announce_press")
    if $DefenceSystem.state_machine.current_state == "powerless":
        if Gotm.user.id == "":
            $Ticker.add_alert("Thank you kind stranger. I don't know how you found this pod, but you've just saved Luna.  We need to keep the shield powered.  If you log on to the GotM system, you'll be well rewarded.")
        else:
            $Ticker.add_alert("Thank heavens, %s, you found the defence pod.  We need to keep the shield powered." % Gotm.user.display_name)
    else:
        if Gotm.user.id == "":
            $Ticker.add_alert("Thank you for your aid stranger. Log in to the GotM system so we can reward you for your aid.")
        else:
            $Ticker.add_alert("Thank you to %s who has just earned $%s defending us all." % [Gotm.user.display_name, $OfferedReward/CurrentReward.get_prize_value()])

func _on_GameJoltAPI_gamejolt_request_completed(type, message, _finished):
    print("_on_GameJoltAPI_gamejolt_request_completed: %s, %s, %s" % [str(type), str(message), str(_finished)])
    if(type == "/data-store/get-keys/"):
        print("    in get-keys")
        for key in message["keys"]:
            if key["key"] != "DefenceSystem":
                key_queue.push_back(key["key"])
                $Benefactors/Benefactors.rewards[key["key"]] = ["", 0]
        if key_queue:
            if $DefenceSystem.state_machine.current_state == "powerless":
                for key in key_queue:
                    $GameJoltAPI.set_data(Gotm.user.id, '["%s",%s]' % [Gotm.user.display_name, 0])
                key_queue = []
            else:
                $GameJoltAPI.fetch_data(key_queue[0])
    elif(type == "/data-store/"):
        print("data-store")
        var key_value = key_queue.pop_front()
        var result

        if key_value == "DefenceSystem" and not message["success"]:
            $DefenceSystem.set_initial_state()
            return
            
        var json_parse = JSON.parse(message["data"])
        
        if json_parse.result:
            result = json_parse.result
        else:
            result = message["data"]

        if key_value == "DefenceSystem":
            $DefenceSystem.set_state_string(result)
            $GameJoltAPI.get_data_keys()
            return
        elif key_value == Gotm.user.id and $DefenceSystem.state_machine.current_state != "powerless":
            $YourReward/YourReward.set_reward(result[1])
        elif $DefenceSystem.state_machine.current_state != "powerless":
            $Benefactors/Benefactors.rewards[key_value] = [result[0],result[1]]
            $Benefactors/Benefactors.update_board()
        else:
            $Benefactors/Benefactors.rewards[key_value] = [result[0],0]
    print("  out if/elif")

func reset_benefactors():
    print("reset_benefactors")
    for benefactor in $Benefactors/Benefactors.rewards:
        $GameJoltAPI.set_data(benefactor, [$Benefactors/Benefactors.rewards[benefactor][0], 0])
    for benefactor in $Benefactors/Benefactors.rewards:
        $Benefactors/Benefactors.rewards[benefactor] = 0
    $Benefactors/Benefactors.update_board()

func start_fetch():
    print("start_fetch")
    if Gotm.lobby.is_host():
        print("  I'm the host")
        key_queue = ["DefenceSystem"]
        $GameJoltAPI.fetch_data("DefenceSystem")
        print("  Requested data keys")
    else:
        print("  I'm not the host")
        key_queue = ["DefenceSystem"]
        $GameJoltAPI.fetch_data("DefenceSystem")
        print("  Sent update request")

remote func request_update():
    print("RPC request_update")
    if Gotm.lobby.is_host():
        print("  Host received update request")
        send_update(false)

func send_update(button_clicked):
    print("send_update: " + str(button_clicked))
    if Gotm.is_live():
        print("  send_update: Called")
        var game_state_str = $DefenceSystem.get_state_string()
        if Gotm.user.id == "":
            print('    rpc("update_game_state", button_clicked, Gotm.user.id, Gotm.user.display_name, $DefenceSystem.stored_reward)')
            rpc("update_game_state", button_clicked, Gotm.user.id, Gotm.user.display_name, $DefenceSystem.stored_reward)
        else:
            print('    rpc("update_game_state", button_clicked, Gotm.user.id, Gotm.user.display_name, $YourReward/YourReward.reward)')
            rpc("update_game_state", button_clicked, Gotm.user.id, Gotm.user.display_name, $YourReward/YourReward.reward)
        print("  send_update: Finished")
        
remote func update_game_state(button_clicked, user_id, display_name, reward): # game_state_str, benefactors):
    print("RPC update_game_state")
    print("    button_clicked: '%s'" % button_clicked)
    print("    user_id: '%s'" % user_id)
    print("    display_name: '%s'" % display_name)
    print("    reward: '%s'" % reward)
    if user_id:
        $Benefactors/Benefactors.rewards[user_id] = [display_name, reward]
        $DefenceSystem.stored_reward = 0
        $Benefactors/Benefactors.update_board()
    else:
        $DefenceSystem.stored_reward = reward
    if button_clicked:
        $DefenceSystem.state_machine.transition("charging")
    else:
        start_fetch()

func _on_DefenceSystem_powerless():
    print("_on_DefenceSystem_powerless")
    $YourReward/YourReward.set_reward(0)
    for key in $Benefactors/Benefactors.rewards:
        $GameJoltAPI.set_data(Gotm.user.id, '["%s",%s]' % [Gotm.user.display_name, 0])
        $Benefactors/Benefactors.rewards[key] = ["", 0]
    $Benefactors/Benefactors.update_board()

func _on_DefenceSystem_reconnect():
    print("_on_DefenceSystem_reconnect")
    start_fetch()

func _on_HostCheckTimer_timeout():
    print("_on_HostCheckTimer_timeout")
    if connecting:
        print("  Connecting")
        return
    if not Gotm.lobby.is_host():
        print("  Sending ping to host")
        rpc_id(1, "ping", get_tree().get_network_unique_id())
        ping_waiting = true
        $PingHostTimer.start()
        return
    print("  fetching")
    var fetch = GotmLobbyFetch.new()
    var lobbies = yield(fetch.first(5), "completed")
    var lobbies_good = []
    for lobby in lobbies:
        print("    - lobby id:" + str(lobby.id))
        print("    lobby peers: " + str(lobby.peers))
        print("    lobby host id: " + str(lobby.host.id))
        print("    lobby host name: " + str(lobby.host.display_name))
        if not(lobby.id in bad_lobbies):
            lobbies_good.append(lobby)
    print("  Creating/choosing lobby.")
    if lobbies_good:
        var other_lobby = lobbies_good[0]
        if other_lobby.id != Gotm.lobby.id and other_lobby.get_property("created") < Gotm.lobby.get_property("created"):
            if Gotm.lobby.peers and Gotm.lobby.is_host():
                print('  rpc("join_lobby", other_lobby)')
                rpc("join_lobby", other_lobby)
            print('  emit_signal("connect_lobby", other_lobby)')
            emit_signal("connect_lobby", other_lobby)


func _on_MainPanel_connect_lobby(lobby):
    print("_on_MainPanel_connect_lobby: %s" % lobby)
    connecting = true
    if lobby:
        print("  Connecting lobby: %s" % lobby.id)
        join_lobby(lobby)
    else:
        lobby_connect()

remote func ping(pingFrom):
    print("RPC ping: " + str(pingFrom))
    if Gotm.lobby.is_host():
        rpc_id(pingFrom, "ping", 1)
    else:
        ping_waiting = false

func _on_PingHostTimer_timeout():
    print("_on_PingHostTimer_timeout")
    if ping_waiting == true:
        bad_lobbies.append(Gotm.lobby.id)
        connecting = true
        emit_signal("connect_lobby", null)
        if $DefenceSystem.state_machine.current_state != 'connecting':
            $DefenceSystem.state_machine.transition('connecting')
