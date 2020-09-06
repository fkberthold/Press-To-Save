extends Node2D

signal out_of_time
signal indicator_time(time)
signal percent_left(percent, time)
signal charged

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var min_degrees = -90
export var max_degrees = 90
export var initial_max_time = 20
export var charge_time = 1
export var time_increment = 10
var degree_range = max_degrees - min_degrees
var max_time = initial_max_time
var time_remaining = max_time
var start_position = min_degrees
var frac_time
var variance = 0.0
var timeout
var running
var charging = charge_time
var charge_rate
var started

# Called when the node enters the scene tree for the first time.
func _ready():
    started = false
    running = false
    charging = false
    timeout = OS.get_unix_time() + time_remaining
    update_meter()
#    pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    if not started:
        rotation_degrees = min_degrees + abs((max_degrees - min_degrees) * ((OS.get_system_time_msecs() % 1000) / 1000.0 - 0.5)) * 2
        return false
    if running:
        time_remaining = timeout - OS.get_unix_time()
        frac_time = (OS.get_system_time_msecs() % 1000) / 1000.0
        update_meter()
        if time_remaining <= 0:
            running = false
            max_time = initial_max_time
            emit_signal("out_of_time")
        elif time_remaining <= 30:
            emit_signal("indicator_time", 30)
            emit_signal("percent_left", float(time_remaining) / float(max_time), time_remaining)
        elif time_remaining <= 120:
            emit_signal("indicator_time", 120)
            emit_signal("percent_left", float(time_remaining) / float(max_time), time_remaining)
        else:
            emit_signal("percent_left", float(time_remaining) / float(max_time), time_remaining)
        if time_remaining <= 0:
            return
        if time_remaining > 0 and not $RunningSound.playing:
            $RunningSound.play()
            $RunningSound.volume_db = -10
        var percent_remaining = float(time_remaining) / float(max_time)
        if percent_remaining <= .1:
            $RunningSound.volume_db = (1-percent_remaining * 10) * -20 - 10
            print("Running: " + str($RunningSound.volume_db))
        else:
            $RunningSound.volume_db = 0
    elif charging:
        time_remaining = timeout - OS.get_unix_time()
        if time_remaining <= 0:
            charging = false
            running = true
            time_remaining = max_time
            timeout = OS.get_unix_time() + time_remaining
            $AnimationPlayer.play("ChargingSoundOff")
            emit_signal("charged")
        update_meter()

func update_meter():
    var frac_time = (OS.get_system_time_msecs() % 1000) / 1000.0
    var degree_range = max_degrees - min_degrees
    if time_remaining == 0:
        rotation_degrees = min_degrees
    elif running:
        rotation_degrees = min_degrees + (degree_range * ((time_remaining - frac_time) / float(max_time)))
    elif charging:
        rotation_degrees = max_degrees - ((max_degrees - start_position) * ((time_remaining - frac_time) / float(charge_time)))
    variance += (randf() - 0.5) * .15
    if running:
        variance = clamp(variance, -2, 1)
    elif charging:
        variance = clamp(variance, -1, 2)
    rotation_degrees = clamp(rotation_degrees + variance, min_degrees, max_degrees)
    
func charge_timeout():
    if charging:
        return timeout
    else:
        return OS.get_unix_time()
    
func shield_timeout():
    if not charging:
        return timeout
    else:
        return timeout + max_time
    
func continue_charge():
    timeout = OS.get_unix_time() + charge_time
    time_remaining = timeout - OS.get_unix_time()
    start_position = min_degrees
    charging = true
    $AnimationPlayer.stop()
    $ChargingSound.seek($ChargingSound.stream.get_length() * (time_remaining / charge_time))
    $ChargingSound.volume_db = -15
    $ChargingSound.play()
    $RunningSound.play()
    $RunningSound.volume_db = -12
    running = false   
    
func start_charge():
    max_time += time_increment
    timeout = OS.get_unix_time() + charge_time
    time_remaining = timeout - OS.get_unix_time()
    start_position = rotation_degrees
    charging = true
    $AnimationPlayer.stop()
    $ChargingSound.volume_db = -15
    $ChargingSound.play()
    $RunningSound.play()
    $RunningSound.volume_db = -12
    print("Max_time: " + str(max_time))
    running = false
