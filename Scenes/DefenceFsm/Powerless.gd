extends "res://addons/fsm/StateMachine.gd".State
class_name Powerless

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _init().():
    process_enabled = true
    enter_state_enabled = true
    leave_state_enabled = true

func _process(_delta: float) -> void:
    if target.aux_time == null:
        state_machine.transition("connecting")
    elif target.charging_timeout < target.time:
        state_machine.transition("charging")
    
func _on_enter_state() -> void:
    print("Enter Powerless")
    
func _on_leave_state() -> void:
    target.change_max_reward()
