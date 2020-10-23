extends "res://addons/fsm/StateMachine.gd".State
class_name AuxPower

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _init().():
    process_enabled = true
    enter_state_enabled = true
    leave_state_enabled = true

func _process(_delta: float) -> void:
    if target.aux_timeout == null:
        state_machine.transition("connecting")
    elif target.aux_timeout < target.time:
        state_machine.transition("powerless")
    elif target.time < target.charging_timeout:
        state_machine.transition("charging")
    else:
        target.update_aux()

func _on_enter_state() -> void:
    print("enter Aux Power: " + str(target.time))
    target.max_shield = target.shieldInit
    target.max_reward = target.initMaxReward
    target.update_aux()
    
func _on_leave_state() -> void:
    print("Exit Aux Power: " + str(target.time))
    target.update_aux()
