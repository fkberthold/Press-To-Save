extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var private_key = "92afbf2d51af6014e5dd41f769371f1a"
var game_id = "513208"
var user_scores = {}
var user_names = {}
var key_queue = []
var started = false
var peer

var display_name = "Zdiles"

# Called when the node enters the scene tree for the first time.
func _ready():
    $GameJoltAPI.init(private_key, game_id)
    key_queue = ["DefenceSystem"]
    $GameJoltAPI.fetch_data("DefenceSystem")
#    $DefenceSystem.set_initial_state()
#    connect_to_lobby()
    
func connect_to_lobby():
    print("User_id: " + Gotm.user.id)
    print("User_name: " + Gotm.user.display_name)
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
        start_fetch()
        return true
    print("Lobby Found")
    var lobby = lobbies[0]
    print("Lobby is: " + str(lobby))
    var success = yield(lobby.join(), "completed")
    print("tried to join lobby")
    print("Lobby Joined: " + str(success))
    peer = NetworkedMultiplayerENet.new()
    print("Host Address straight: " + str(Gotm.lobby.host.address))
    print("Host Address: " + str(Gotm.lobby.host.address))
    peer.create_client(Gotm.lobby.host.address, 8070)
    get_tree().set_network_peer(peer)
    print("Client created")
    start_fetch()
    return true

func create_new_lobby():
    print("Creating Lobby")
    Gotm.host_lobby(false)
    print("Hosting Library")
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
func set_reward(reward_value):
    print("Setting reward: %s" % reward_value)
    $YourReward/YourReward.add_reward(reward_value)
#    if Gotm.user.display_name in $Benefactors/Benefactors.rewards:
#        $Benefactors/Benefactors.rewards[Gotm.user.display_name] += reward_value
#    else:
#        $Benefactors/Benefactors.rewards[Gotm.user.display_name] = reward_value
#    $Benefactors/Benefactors.update_board()
#    $GameJoltAPI.set_data(Gotm.user.id + "_reward", $YourReward/YourReward.reward)
#    $GameJoltAPI.set_data(Gotm.user.id + "_name", Gotm.user.display_name)

func _on_ShieldButton_button_down():
    if not $DefenceSystem.state_machine.current_state in ['charging', 'connecting']:
        announce_press()
        set_reward($OfferedReward/CurrentReward.get_prize_value())
        $Ticker.active = true
        $DefenceSystem.state_machine.transition('charging')
        $GameJoltAPI.set_data("DefenceSystem", $DefenceSystem.get_state_string())
#    print("Button Down!")
#    print("Charging: " + str($Meter.charging))
#    print("started: " + str(started))
#    if not($Meter.charging) and started:
#        $Meter.start_charge()
#        $AuxPower/AUXTime.stop_timer()
#        $AuxPower/AUXTime.update_display()
#        if Gotm.user.id == null:
#            $OfferedReward/CurrentReward.stored_value = $OfferedReward/CurrentReward.prize_value
#            $GameJoltAPI.set_data("Stored_value", $OfferedReward/CurrentReward.stored_value)
#        else:
#            set_reward($OfferedReward/CurrentReward.get_prize_value())
#        $OfferedReward/CurrentReward.set_new_max()
#        $OfferedReward/CurrentReward.prize_value = 0
#        $OfferedReward/CurrentReward.update_display()
#        $GameJoltAPI.set_data("timeouts", $DefenceSystem.get_timeouts())
#        $GameJoltAPI.set_data("Shield_max", $Meter.max_time)
#        $GameJoltAPI.set_data("Max_Reward", $OfferedReward/CurrentReward.current_max)
#        send_update(true)

func announce_press():
    if $DefenceSystem.state_machine.current_state == "powerless":
        $Ticker.add_alert("Thank heavens, %s, you found the defence pod.  We need to keep the shield powered." % display_name)
    else:
        $Ticker.add_alert("Thank you to %s who has just earned $%s defending us all." % [display_name, $OfferedReward/CurrentReward.get_prize_value()])

func _on_GameJoltAPI_gamejolt_request_completed(type, message, finished):
    print([type, message, finished])
    print(key_queue)
    if(false and type == "/data-store/get-keys/"):
        for key in message["keys"]:
            if key != "DefenceSystem":
                key_queue.push_back(key["key"])
        if key_queue:
            $GameJoltAPI.fetch_data(key_queue[0])
    elif(type == "/data-store/"):
        var key_value = key_queue.pop_front()
        var result

        print(message)
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
        return

        if(Gotm.user.id and key_value == Gotm.user.id + "_reward"):
            $YourReward/YourReward.set_reward(int(result))
        if("_reward" in key_value):
            user_scores[key_value.split("_")[0]] = int(result)
            $Benefactors/Benefactors.ids[key_value.split("_")[0]] = null
        elif("_name" in key_value):
            user_names[key_value.split("_")[0]] = result
        elif("game_state" in key_value):
            $DefenceSystem.set_state_string(result)
            
        if(key_queue):
            $GameJoltAPI.fetch_data(key_queue[0])
        else:
            for user_id in user_names:
                $Benefactors/Benefactors.rewards[user_names[user_id]] = user_scores[user_id]
                $Benefactors/Benefactors.update_board()
    return
    if key_queue == [] and not started:
        $Ticker.started = true
        $Meter.started = true
        $AuxPower/AUXTime.started = true
        started = true
        $OfferedReward/CurrentReward.started = true
        $AuxPower/AUXTime.set_by_end_time($AuxPower/AUXTime.time_timeout, $Meter.shield_timeout())
        if $AuxPower/AUXTime.running:
            $OfferedReward/CurrentReward.current_max = $OfferedReward/CurrentReward.initial_max
            $Meter.max_time = $Meter.initial_max_time
        if $AuxPower/AUXTime.time_left == 0:
            reset_system()
        $Meter.update_meter()
        $AuxPower/AUXTime.update_display()
        $OfferedReward/CurrentReward.update_display()

func reset_system():
    $AuxPower/AUXTime.stop_timer()
    $AuxPower/AUXTime.time_left = 0
    $AuxPower/AUXTime.tsecs = 0
    $AuxPower/AUXTime.time_timeout = OS.get_unix_time()
    $AuxPower/AUXTime.update_display()
    $OfferedReward/CurrentReward.current_max = int($OfferedReward/CurrentReward.initial_max)
    $OfferedReward/CurrentReward.prize_value = 0
    $OfferedReward/CurrentReward.update_display()
    $YourReward/YourReward.set_reward(0)
    $GameJoltAPI.set_data("AUXTime_left", 0)
    $GameJoltAPI.set_data("Charge_timeout", OS.get_unix_time())
    $GameJoltAPI.set_data("Shield_timeout", OS.get_unix_time())
    $GameJoltAPI.set_data("Shield_max", $Meter.max_time)
    $GameJoltAPI.set_data("Max_Reward", $OfferedReward/CurrentReward.current_max)
    reset_benefactors()
    
func reset_benefactors():
    for benefactor in $Benefactors/Benefactors.ids:
        $GameJoltAPI.set_data(benefactor + "_reward", 0)
    for benefactor in $Benefactors/Benefactors.rewards:
        $Benefactors/Benefactors.rewards[benefactor] = 0
    $Benefactors/Benefactors.update_board()

func _on_AUXTime_out_of_aux_time():
    reset_system()

func start_fetch():
    print("Checking if I'm the host")
    if Gotm.lobby.is_host():
        print("I'm the host")
        $GameJoltAPI.get_data_keys()
        print("Requested data keys")
    else:
        print("I'm not the host")
        $RetryFetchTimer.start()
        rpc("request_update")
        print("Sent update request")

remote func request_update():
    print("Recieved update request")
    if Gotm.lobby.is_host():
        print("Host recieved update request")
        send_update(false)

func send_update(button_clicked):
    print("send_update: Called")
    rpc("update_game_state", button_clicked, $AuxPower/AUXTime.time_end, $Meter.charge_timeout(), $Meter.shield_timeout(), $Meter.max_time,
        $OfferedReward/CurrentReward.current_max, $OfferedReward/CurrentReward.stored_value, $Benefactors/Benefactors.rewards, 
        $Benefactors/Benefactors.ids)
    print("send_update: Finished")
        
remote func update_game_state(button_clicked, AUXTime_timeout, Charge_timeout, Shield_timeout, Shield_max, Max_Reward, Stored_value, benefactors_rewards, benefactors_ids):
    $OfferedReward/CurrentReward.stored_value = Stored_value
    $AuxPower/AUXTime.set_by_end_time(AUXTime_timeout, Shield_timeout)
    $Meter.max_time = Shield_max
    if Charge_timeout > OS.get_unix_time():
        $Meter.timeout = Charge_timeout
        $Meter.time_remaining = $Meter.timeout - OS.get_unix_time()
        $OfferedReward/CurrentReward.running = false
        $AuxPower/AUXTime.running = false
        if button_clicked:
            $Meter.start_charge()
        else:
            $Meter.continue_charge()
    elif Shield_timeout > OS.get_unix_time():
        $Meter.timeout = Shield_timeout
        $Meter.time_remaining = $Meter.timeout - OS.get_unix_time()
        $Meter.running = true
        $AuxPower/AUXTime.running = false
        $OfferedReward/CurrentReward.running = true
    else:
        $Meter.charging = false
        $Meter.running = false
        $AuxPower/AUXTime.running = true
        $OfferedReward/CurrentReward.running = false
    $Meter.max_time = Shield_max
    $OfferedReward/CurrentReward.current_max = Max_Reward
    $Benefactors/Benefactors.rewards = benefactors_rewards
    $Benefactors/Benefactors.ids = benefactors_ids

    $Ticker.started = true
    $Meter.started = true
    $AuxPower/AUXTime.started = true
    started = true
    $OfferedReward/CurrentReward.started = true
    if $AuxPower/AUXTime.running:
        $AuxPower/AUXTime.time_timeout = $Meter.timeout + $AuxPower/AUXTime.time_left
        $AuxPower/AUXTime.time_left = int(max($AuxPower/AUXTime.time_timeout - OS.get_unix_time(), 0))
        $OfferedReward/CurrentReward.current_max = $OfferedReward/CurrentReward.initial_max
        $Meter.max_time = $Meter.initial_max_time
    if $AuxPower/AUXTime.time_left == 0:
        reset_system()
    $Meter.update_meter()
    $AuxPower/AUXTime.update_display()
    $OfferedReward/CurrentReward.update_display()
    $Benefactors/Benefactors.update_board()
    print("update_game_state: Finished")


func _on_RetryFetchTimer_timeout():
    if not started:
        start_fetch()
