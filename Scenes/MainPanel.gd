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
var alert_queue = []

func _ready():
    $GameJoltAPI.init(private_key, game_id)
    if Gotm.is_live():
        Gotm.connect("lobby_changed", self, "_on_lobby_changed")
        lobby_connect()
    else:
#        Gotm.user.id = "X0"
#        Gotm.user.display_name = "Zdiles"
        Gotm.user.id = ""
        Gotm.user.display_name = ""
        key_queue = ["DefenceSystem"]
        $GameJoltAPI.fetch_data("DefenceSystem")

remote func join_lobby(new_lobby):
    var success = yield(new_lobby.join(), "completed")
    var peer = NetworkedMultiplayerENet.new()
    peer.create_client(Gotm.lobby.host.address, 8070)  
    get_tree().set_network_peer(peer)

func lobby_connect():
    var fetch = GotmLobbyFetch.new()
    var lobbies = yield(fetch.first(5), "completed")
    for lobby in lobbies:
        if lobby.id in bad_lobbies:
            continue
        var success = yield(lobby.join(), "completed")
        if not success:
            bad_lobbies.append(lobby.id)
            continue
        peer = NetworkedMultiplayerENet.new()
        peer.create_client(Gotm.lobby.host.address, 8070)  
        get_tree().set_network_peer(peer)
        return
    Gotm.host_lobby(false)
    Gotm.lobby.name = str(OS.get_system_time_msecs())
    Gotm.lobby.hidden = false
    peer = NetworkedMultiplayerENet.new()
    peer.create_server(8070)
    get_tree().set_network_peer(peer)

func _on_lobby_changed():
    if Gotm.lobby:
        get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
        get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
        if Gotm.lobby.is_host():
            Gotm.lobby.set_property("created", OS.get_system_time_msecs())
        $HostCheckTimer.start()
        connecting = false
    else:
        $HostCheckTimer.stop()
        lobby_connect()
        emit_signal("connect_lobby", null)
        
func _on_network_peer_connected(peer):
    if not Gotm.lobby.is_host():
        request_update()
    else:
        send_update(false)
    
func _on_network_peer_disconnected(peer):
    if not Gotm.lobby.is_host():
        request_update()
    else:
        send_update(false)

func set_reward(reward_value):
    $YourReward/YourReward.add_reward(reward_value)
    $GameJoltAPI.set_data(Gotm.user.id, '["%s",%s]' % [Gotm.user.display_name, $YourReward/YourReward.reward])
    $Benefactors/Benefactors.rewards[Gotm.user.id] = [Gotm.user.display_name, $YourReward/YourReward.reward]
    $Benefactors/Benefactors.update_board()

func _on_ShieldButton_button_down():
    if not $DefenceSystem.state_machine.current_state in ['charging', 'connecting']:
        announce_press()
        $Ticker.active = true
        if Gotm.user.id == "":
            $DefenceSystem.stored_reward = $OfferedReward/CurrentReward.get_prize_value()
            $DefenceSystem.state_machine.transition('charging')
            $GameJoltAPI.set_data("log_" + str(OS.get_unix_time()), "NO_NAME : " + $DefenceSystem.get_state_string())
            $GameJoltAPI.set_data("DefenceSystem", $DefenceSystem.get_state_string())
        else:
            set_reward($OfferedReward/CurrentReward.get_prize_value())
            $DefenceSystem.stored_reward = 0
            $DefenceSystem.state_machine.transition('charging')
            $GameJoltAPI.set_data("log_" + str(OS.get_unix_time()), Gotm.user.display_name + " : " + $DefenceSystem.get_state_string())
            $GameJoltAPI.set_data("DefenceSystem", $DefenceSystem.get_state_string())
        send_update(true)

func announce_press():
    if $DefenceSystem.state_machine.current_state == "powerless":
        if Gotm.user.id == "":
            if alert_queue:
                $Ticker.add_alert(alert_queue.pop_front())
            else:    
                $Ticker.add_alert("Thank you kind stranger.")
                $Ticker.add_alert("You've just saved Luna.")
                $Ticker.add_alert("We must keep the shield powered.")
                $Ticker.add_alert("Log in to the GotM system (the game website)")
                $Ticker.add_alert("Refresh when you've logged in to be rewarded.")
                $Ticker.add_alert("Watch this display for alerts,")
                $Ticker.add_alert("News and entertainment will also be shown.")
            rpc("alert", "A stranger begun the fight to protect Luna!")
        else:
            if alert_queue:
                $Ticker.add_alert(alert_queue.pop_front())
            else:
                $Ticker.add_alert("%s you've just saved Luna." % Gotm.user.display_name)
                $Ticker.add_alert("We must keep the shield powered.")
                $Ticker.add_alert("Watch this display for alerts,")
                $Ticker.add_alert("News and entertainment will also be shown.")
            rpc("alert", "%s has begun the fight to protect Luna!" % Gotm.user.display_name)
    else:
        if Gotm.user.id == "":
            if alert_queue:
                $Ticker.add_alert(alert_queue.pop_front())
            else:
                $Ticker.add_alert("Thank you kind stranger.")
                $Ticker.add_alert("%s you've just saved Luna.")
                $Ticker.add_alert("We must keep the shield powered.")
                $Ticker.add_alert("Watch this display for alerts,")
                $Ticker.add_alert("News and entertainment will also be shown.")
            rpc("alert", "A stranger has powered the shield, new bounty: $%s" % $DefenceSystem.stored_reward)
        elif Gotm.user.id in $Benefactors/Benefactors.rewards:
            if alert_queue:
                for alert_str in alert_queue:
                    $Ticker.add_alert(alert_str)
            else:
                $Ticker.add_alert("Thank You %s. Bounty Earned: $%s" % [Gotm.user.display_name, $OfferedReward/CurrentReward.get_prize_value()])
        else:
            $Ticker.add_alert("Thank You %s. Bounty Earned: $%s" % [Gotm.user.display_name, $OfferedReward/CurrentReward.get_prize_value()])
            $Ticker.add_alert("We must keep the shield powered.")
            $Ticker.add_alert("Watch this display for alerts,")
            $Ticker.add_alert("News and entertainment will also be shown.")

            rpc("alert", "%s earned Bounty: $%s." % [Gotm.user.display_name, $OfferedReward/CurrentReward.get_prize_value()])

remote func alert(message):
    $Ticker.add_alert(message)

func _on_GameJoltAPI_gamejolt_request_completed(type, message, _finished):
    if(type == "/data-store/get-keys/"):
        for key in message["keys"]:
            if key["key"] != "DefenceSystem" and key["key"].substr(0,4) != "log_":
                key_queue.push_back(key["key"])
                if not(key in $Benefactors/Benefactors.rewards):
                    $Benefactors/Benefactors.rewards[key["key"]] = ["", 0]
                    $Benefactors/Benefactors.update_board()
        if key_queue:
            if $DefenceSystem.state_machine.current_state == "powerless":
                for key in key_queue:
                    $GameJoltAPI.set_data(Gotm.user.id, '["%s",%s]' % [Gotm.user.display_name, 0])
                key_queue = []
            else:
                $GameJoltAPI.fetch_data(key_queue[0])
    elif(type == "/data-store/"):
        var key_value = key_queue.pop_front()
        var result

        if key_value == "DefenceSystem" and not message["success"]:
            $DefenceSystem.set_initial_state()
            $GameJoltAPI.set_data("DefenceSystem", $DefenceSystem.get_state_string())
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
            $Benefactors/Benefactors.rewards[key_value] = [result[0],result[1]]
            $Benefactors/Benefactors.update_board()
        elif $DefenceSystem.state_machine.current_state != "powerless":
            $Benefactors/Benefactors.rewards[key_value] = [result[0],result[1]]
            $Benefactors/Benefactors.update_board()
        else:
            $Benefactors/Benefactors.rewards[key_value] = [result[0],0]
            $GameJoltAPI.set_data(key_value, '["%s",%s]' % [result[0], 0])
        if key_queue:
            $GameJoltAPI.fetch_data(key_queue[0])

func start_fetch():
    if Gotm.lobby.is_host():
        key_queue = ["DefenceSystem"]
        $GameJoltAPI.fetch_data("DefenceSystem")
    else:
        key_queue = ["DefenceSystem"]
        $GameJoltAPI.fetch_data("DefenceSystem")

remote func request_update():
    if Gotm.lobby.is_host():
        send_update(false)

func send_update(button_clicked):
    if Gotm.is_live():
        var game_state_str = $DefenceSystem.get_state_string()
        if Gotm.user.id == "":
            rpc("update_game_state", button_clicked, Gotm.user.id, Gotm.user.display_name, $DefenceSystem.stored_reward)
        else:
            rpc("update_game_state", button_clicked, Gotm.user.id, Gotm.user.display_name, $YourReward/YourReward.reward)
        
remote func update_game_state(button_clicked, user_id, display_name, reward):
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
    $YourReward/YourReward.set_reward(0)
    for key in $Benefactors/Benefactors.rewards:
        $GameJoltAPI.set_data(key, '["%s",%s]' % [Gotm.user.display_name, 0])
        $Benefactors/Benefactors.rewards[key] = ["", 0]
    $Benefactors/Benefactors.update_board()

func _on_DefenceSystem_reconnect():
    start_fetch()

func _on_HostCheckTimer_timeout():
    if connecting:
        return
    if not Gotm.lobby.is_host():
        rpc_id(1, "ping", get_tree().get_network_unique_id())
        ping_waiting = true
        $PingHostTimer.start()
        return
    var fetch = GotmLobbyFetch.new()
    var lobbies = yield(fetch.first(5), "completed")
    var lobbies_good = []
    for lobby in lobbies:
        if not(lobby.id in bad_lobbies):
            lobbies_good.append(lobby)
    if lobbies_good:
        var other_lobby = lobbies_good[0]
        if other_lobby.id != Gotm.lobby.id and other_lobby.get_property("created") < Gotm.lobby.get_property("created"):
            if Gotm.lobby.peers and Gotm.lobby.is_host():
                rpc("join_lobby", other_lobby)
            emit_signal("connect_lobby", other_lobby)


func _on_MainPanel_connect_lobby(lobby):
    connecting = true
    if lobby:
        join_lobby(lobby)
    else:
        lobby_connect()

remote func ping(pingFrom):
    if Gotm.lobby.is_host():
        rpc_id(pingFrom, "ping", 1)
    else:
        ping_waiting = false

func _on_PingHostTimer_timeout():
    if ping_waiting == true:
        bad_lobbies.append(Gotm.lobby.id)
        connecting = true
        emit_signal("connect_lobby", null)
        if $DefenceSystem.state_machine.current_state != 'connecting':
            $DefenceSystem.state_machine.transition('connecting')
