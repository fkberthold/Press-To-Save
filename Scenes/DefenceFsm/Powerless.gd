extends "res://addons/fsm/StateMachine.gd".State
class_name Powerless

func _init().():
    process_enabled = true
    enter_state_enabled = true
    leave_state_enabled = true

func _process(_delta: float) -> void:
    if target.aux_timeout == null:
        state_machine.transition("connecting")
    
func _on_enter_state() -> void:
    print("Enter Powerless: " + str(target.time))
    target.powerless()
    
func _on_leave_state() -> void:
    print("Exit Powerless" + str(target.time))
    target.change_max_reward()
