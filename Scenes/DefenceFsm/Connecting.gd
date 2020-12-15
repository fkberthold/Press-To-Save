extends "res://addons/fsm/StateMachine.gd".State
class_name Connecting

const connect_time = 0.2
var time = 0

func _init().():
    process_enabled = true
    enter_state_enabled = true
    leave_state_enabled = true

func _process(delta: float) -> void:
    time += delta
    if time >= connect_time:
        time = 0
        target.try_connect()
    
func _on_enter_state() -> void:
    print("Enter Connecting: " + str(target.time))
    target.update_aux()
    target.update_shield()
    
func _on_leave_state() -> void:
    print("Exit Connecting: " + str(target.time))
    target.update_aux()
    target.update_shield()
