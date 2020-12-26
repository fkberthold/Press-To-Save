extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var min_degrees = -90
export var max_degrees = 90
export var variance_range = 1
onready var degree_range = max_degrees - min_degrees
var variance = 0.0
var charging_started = false
var time_at_full = 0

func _ready():
    degree_range = max_degrees - min_degrees
    rotation_degrees = min_degrees

func _on_DefenceSystem_update_shield(charging, time_left, percent_left):
    if not (min_degrees and degree_range and percent_left):
        return

    rotation_degrees = clamp(min_degrees + (degree_range * clamp(percent_left, 0.0, 1.0)), min_degrees, max_degrees)

    if charging and not charging_started:
        $ChargingSound.play()
        $RunningSound.stop()
        $FailingSound.stop()
    elif charging_started and not charging:
        $RunningSound.play()
        $FailingSound.play()
        time_at_full = time_left
        $RunningSound.volume_db = -40
        $FailingSound.volume_db = -40
    elif (not charging) and (not $RunningSound.playing) and (percent_left > 0):
        $RunningSound.play()
        $FailingSound.play()
    elif not charging and time_at_full - time_left <= 1.0:
        $RunningSound.volume_db = -40 + (ease(time_at_full - time_left, 0.4) * 40)
    elif not charging and percent_left <= 0.4 and time_left > 1.0:
        $RunningSound.volume_db = -40 + (ease(percent_left * 2.5, -0.2) * 50)
        $FailingSound.volume_db = -40 + (ease(1 - percent_left * 2.5, 2) * 40)
    elif time_left <= 0.1:
        $RunningSound.stop()
        $FailingSound.stop()
    charging_started = charging
    
