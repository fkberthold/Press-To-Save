extends Node

signal reconnect
signal update_aux(running, time_left)
signal update_shield(charging, time_left, percent_left)
signal update_reward(reward)

export var shieldIncrement = 10
export var auxIncrement = 30
export var shieldInit = 10 # 30
export var auxInit = 0
export var chargeTime = 10
export var initMaxReward = 2
export var rewardIncrement = 10.0

const StateMachineFactory = preload("res://addons/fsm/StateMachineFactory.gd")
const PowerlessState = preload("DefenceFsm/Powerless.gd")
const ChargingState = preload("DefenceFsm/Charging.gd")
const AuxPowerState = preload("DefenceFsm/AuxPower.gd")
const ShieldedState = preload("DefenceFsm/Shielded.gd")
const ConnectingState = preload("DefenceFsm/Connecting.gd")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var state_machine: StateMachine
var charging_timeout = null
var shield_timeout = null
var aux_timeout = null
var charging_start = 0

var max_shield = null

var stored_reward = 0
var current_reward = 0
var max_reward = 0

var time = null
var time_offset = null
onready var smf = StateMachineFactory.new()

var reset_state = false
var set_state = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    request_unix_time()
    state_machine = smf.create({
        "target": self,
        "current_state": "connecting",
        "states": [
            {"id": "connecting", "state": ConnectingState},
            {"id": "powerless", "state": PowerlessState},
            {"id": "charging", "state": ChargingState},
            {"id": "shielded", "state": ShieldedState},
            {"id": "aux_power", "state": AuxPowerState}
        ],
        "transitions": [
            {"state_id": "connecting", "to_states": []},
            {"state_id": "powerless", "to_states": ["charging","connecting"]},
            {"state_id": "charging", "to_states": ["shielded","connecting"]},
            {"state_id": "shielded", "to_states": ["charging", "aux_power","connecting"]},
            {"state_id": "aux_power", "to_states": ["charging", "powerless","connecting"]}
            ]
    })


func get_state_string():
    return "[%s,%s,%s,%s,%s,%s,%s]" % [aux_timeout, charging_timeout, shield_timeout, max_shield, stored_reward, current_reward, max_reward]

func set_initial_state():
    if time:
        aux_timeout = 0
        charging_timeout = 0
        shield_timeout = 0
        max_shield = shieldInit
        stored_reward = 0
        current_reward = 0
        max_reward = initMaxReward
        update_aux()
    else:
        reset_state = true
        

func set_state_string(state_array):
    if time:
        aux_timeout = state_array[0]
        charging_timeout = state_array[1]
        shield_timeout = state_array[2]
        max_shield = state_array[3]
        stored_reward = state_array[4]
        current_reward = state_array[5]
        max_reward = state_array[6]
        if charging_timeout > time:
            state_machine.current_state = "charging"
        elif shield_timeout > time:
            state_machine.current_state = "shielded"
        elif aux_timeout > time:
            stored_reward = 0
            current_reward = 0
            state_machine.current_state = "aux_power"
            max_shield = shieldInit
        else:
            stored_reward = 0
            current_reward = 0
            state_machine.current_state = "powerless"
            max_shield = shieldInit
        update_aux()
        update_current_reward()
        update_shield()
    else:
        set_state = state_array

# This is required so that our FSM can handle updates
func _input(event: InputEvent) -> void:
    state_machine._input(event)

func _process(delta: float) -> void:
    if time == null:
        return
    time += delta
#    print(state_machine.current_state + ": " + str(aux_timeout - time) + ":" + str(shield_timeout - time) + ":" + str(charging_timeout - time))
#    print("aux_left: " + str(max(0, min(aux_timeout - time, aux_timeout - shield_timeout))))
    var drift = abs(time - (OS.get_unix_time() + time_offset))
    if drift > 2.0:
        request_unix_time()
        time = null
        state_machine.transition("connecting")
    state_machine._process(delta)

func change_max_reward():
    if state_machine.current_state == "shielded" and (time < shield_timeout):
        var percent = clamp((shield_timeout - time) / max_shield, 0, 1)
        if percent >= .5:
            max_reward = max_reward + round(ease((percent + 0.5) * 2, -2.2) * rewardIncrement)
        else:
            max_reward = max(initMaxReward, round(ease(percent * 2, -2.2) * max_reward))
    else:
        max_reward = initMaxReward
    print("max reward: %s" % max_reward)

func request_unix_time():
    $HTTPRequest.request("https://worldtimeapi.org/api/timezone/Etc/UTC")

func _on_HTTPRequest_request_completed(_result, response_code, _headers, body):
    if response_code == 200:
        var json = JSON.parse(body.get_string_from_utf8())
        time = float(json.result['unixtime'])
        time_offset = time - OS.get_unix_time()
        if reset_state:
            set_initial_state()
        elif set_state:
            set_state_string(set_state)
            set_state = []
    else:
        request_unix_time()
        emit_signal("reconnect")

func update_aux():
    if not time:
        emit_signal("update_aux", false, null)
        return
        
    var aux_timeleft = max(0, min(aux_timeout - time, aux_timeout - shield_timeout))
    if state_machine.current_state == "connecting":
        emit_signal("update_aux", false, aux_timeleft)
    elif state_machine.current_state == "aux_power":
        emit_signal("update_aux", true, aux_timeleft)
    else:
        emit_signal("update_aux", false, aux_timeleft)

func update_shield():
    if state_machine.current_state == "connecting":
        emit_signal("update_shield", null, null, null)
    elif state_machine.current_state == "charging":
        emit_signal("update_shield", true, max(0, charging_timeout - time), max(0, charging_start + (1.0 - charging_start) * (chargeTime - (charging_timeout - time)) / chargeTime))
    elif state_machine.current_state == "shielded":
        emit_signal("update_shield", false, max(0, shield_timeout - time), max(0, (shield_timeout - time) / max_shield))
    else:
        emit_signal("update_shield", false, 0)

func update_current_reward():
    if state_machine.current_state == "shielded" and (time < shield_timeout):
        var percent = clamp(1 - (shield_timeout - time) / max_shield, 0, 1)
        var logEase = stored_reward + round(ease(percent, 0.4) * max_reward)
        var tanEase = stored_reward + round(ease(percent, -0.4) * max_reward)
        emit_signal("update_reward", min(logEase, tanEase))
    else:
        emit_signal("update_reward", 0)
