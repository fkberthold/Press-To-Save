extends "res://addons/fsm/StateMachine.gd".State
class_name Shielded

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _init().():
    process_enabled = true
    enter_state_enabled = true
    leave_state_enabled = true

func _process(_delta: float) -> void:
    if target.shield_timeout == null:
        state_machine.transition("connecting")
    elif target.shield_timeout < target.time:
        target.shield_timeout = target.time
        state_machine.transition("aux_power")
    elif target.time < target.charging_timeout:
        state_machine.transition("charging")
    else:
        target.update_current_reward()
        target.update_shield()

func _on_enter_state() -> void:
    pass
    
func _on_leave_state() -> void:
    var time_left = target.shield_timeout - target.time
    if time_left > 0:
        target.charging_start = time_left/target.max_shield
    else:
        target.charging_start = 0
    target.change_max_reward()
    target.update_shield()
    target.update_current_reward()
