extends "res://addons/fsm/StateMachine.gd".State
class_name Connecting

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _init().():
    process_enabled = true
    enter_state_enabled = true
    leave_state_enabled = true

func _process(_delta: float) -> void:
    pass
#    if target.time == null or target.aux_timeout == null:
#        return
#    if target.time > target.aux_timeout:
#        state_machine.transition('powerless')
#    elif target.time > target.shield_timeout:
#        state_machine.transition('aux_power')
#    elif target.time > target.charging_timeout:
#        state_machine.transition('shielded')
#    else:
#        state_machine.transition('charging')
    
func _on_enter_state() -> void:
    print("Enter Connecting: " + str(target.time))
    target.update_aux()
    target.update_shield()
    
func _on_leave_state() -> void:
    print("Exit Connecting: " + str(target.time))
    target.update_aux()
    target.update_shield()
