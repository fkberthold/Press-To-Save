extends "res://addons/fsm/StateMachine.gd".State
class_name Charging

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _init().():
    process_enabled = true
    enter_state_enabled = true
    leave_state_enabled = true

func _process(_delta: float) -> void:
    if target.aux_timeout == null or target.time == null:
        state_machine.transition("connecting")
    elif target.charging_timeout < target.time:
        state_machine.transition("shielded")
    else:
        target.update_shield()

func _on_enter_state() -> void:
    print("Enter Charging: " + str(target.time))
    target.max_shield += target.shieldIncrement
    target.charging_timeout = target.time + target.chargeTime
    if target.shield_timeout > target.time:
        target.max_shield += target.shieldIncrement
        target.shield_timeout = target.charging_timeout + target.max_shield
    else:
        target.shield_timeout = target.charging_timeout + target.max_shield
        
    if target.aux_timeout > target.time:
        target.aux_timeleft = target.aux_timeleft + target.auxIncrement
    else:
        target.aux_timeleft = target.auxIncrement
    target.aux_timeout = target.shield_timeout + target.aux_timeleft

    target.update_aux()
    target.update_current_reward()
            
func _on_leave_state() -> void:
    print("Exit Charging: " + str(target.time))
