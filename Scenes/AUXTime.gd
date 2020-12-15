extends Label

export var increase_by = 30
#var time_offset = 0
var tsecs = 0
var time_timeout = 0
var started
var at0 = false
var ticked = false
var tick = 0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#func init(aux_time_left):
#    time_left = int(aux_time_left)
#    end_time = OS.get_unix_time() + time_left

# Called when the node enters the scene tree for the first time.
func _ready():
    text = ""

            
func play_tick(tick_index):
    $ticks.get_children()[tick_index % ($ticks.get_child_count() - 1)].play()

func update_display(running, time_left):
    if not time_left and time_left != 0:
        text = "00:00:00.0"
        return
    var seconds_tenths = str(int(time_left * 10) % 10)
    var seconds = str(int(time_left) % 60)
    if len(seconds) == 1:
        seconds = "0" + seconds
    var minutes = str(int(time_left / 60) % 60)
    if len(minutes) == 1:
        minutes = "0" + minutes
    var hours = str(int(time_left / (60 * 60)))
    if len(hours) == 1:
        hours = "0" + hours

    if running and seconds_tenths == "0" and not ticked:
        play_tick(int(seconds))
        ticked = true
    elif seconds_tenths != "0":
        ticked = false
    text = hours + ":" + minutes + ":" + seconds + "." + seconds_tenths


func _on_DefenceSystem_update_aux(running, time_left):
    update_display(running, time_left)
