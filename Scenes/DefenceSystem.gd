extends Node

signal reconnect
signal update_aux(time_left)
signal update_shield(charging, percent_left)

export var shieldIncrement = 10
export var auxIncrement = 30
export var shieldInit = 30
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

var max_shield = null

var stored_reward = 0
var current_reward = 0
var max_reward = 0

var time = null
var time_offset = null
onready var smf = StateMachineFactory.new()
var counter = 0

func init_state(charge_to, shield_to, aux_to) -> void:
    charging_timeout = charge_to
    shield_timeout = shield_to
    aux_timeout = aux_to


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
            {"state_id": "connecting", "to_states": ["charging","shielded","aux_power","powerless", "connecting"]},
            {"state_id": "powerless", "to_states": ["charging","connecting"]},
            {"state_id": "charging", "to_states": ["shielded","connecting"]},
            {"state_id": "shielded", "to_states": ["charging", "aux_power","connecting"]},
            {"state_id": "aux_power", "to_states": ["charging", "powerless","connecting"]}
            ]
    })


func get_state_string():
    return "%f,%f,%f,%f,%f,%f,%f" % [aux_timeout, charging_timeout, shield_timeout, max_shield, stored_reward, current_reward, max_reward]

func set_state_string(state_string: String):
    [max_shield, aux_timeout, charging_timeout, shield_timeout, max_shield, stored_reward, current_reward, max_reward] = state_string.split(",")

# This is required so that our FSM can handle updates
func _input(event: InputEvent) -> void:
    state_machine._input(event)

func _process(delta: float) -> void:
    counter += delta
    if time == null:
        return
    time += delta
    var drift = abs(time - (OS.get_unix_time() + time_offset))
    if drift > 2.0:
        request_unix_time()
        time = null
        state_machine.transition("connecting")
        print("Drifted")
    state_machine._process(delta)
    if counter > 1.0:
        print("time: " + str(time))
        counter = 0

func change_max_reward():
    if state_machine.current_state == "shielded" and (time < charging_timeout):
        var percent = max(0, (charging_timeout - time) / max_shield)
        if percent >= .5:
            max_reward = max_reward + round(ease((percent - 0.5) * 2, -2.2) * rewardIncrement)
        else:
            max_reward = max(initMaxReward, round(ease(percent * 2, -2.2) * max_reward))
    else:
        max_reward = initMaxReward 
    emit_signal("max_reward", max_reward)     

func request_unix_time():
    $HTTPRequest.request("http://worldtimeapi.org/api/timezone/Etc/UTC")

func _on_HTTPRequest_request_completed(_result, response_code, _headers, body):
    if response_code == 200:
        var json = JSON.parse(body.get_string_from_utf8())
        time = float(json.result['unixtime'])
        time_offset = time - OS.get_unix_time()
    else:
        request_unix_time()
        emit_signal("reconnect")

func update_aux():
    if state_machine.current_state == "connecting":
        emit_signal("update_aux", null)
    else:
        emit_signal("update_aux", max(0, aux_timeout - time))

func update_shield():
    if state_machine.current_state == "connecting":
        emit_signal("update_shield", null)
    elif state_machine.current_state == "charging":
        emit_signal("update_shield", true, max(0, (charging_timeout - time) / max_shield))
    elif state_machine.current_state == "shielded":
        emit_signal("update_shield", false, max(0, (charging_timeout - time) / chargeTime))
    else:
        emit_signal("update_shield", true, 0)

func update_current_reward():
    if state_machine.current_state == "shielded" and (time < charging_timeout):
        var percent = max(0, (charging_timeout - time) / max_shield)
        var logEase = stored_reward + round(ease(percent, 0.4) * max_reward)
        var tanEase = stored_reward + round(ease(percent, -0.4) * max_reward)
        emit_signal("update_reward", min(logEase, tanEase))
    else:
        emit_signal("update_reward", 0)
