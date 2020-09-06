extends Label

signal out_of_aux_time

export var increase_by = 30
var time_left =  0
#var time_offset = 0
var tsecs = 0
var time_timeout = 0
var running = false
var started
var at0 = false
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#func init(aux_time_left):
#    time_left = int(aux_time_left)
#    end_time = OS.get_unix_time() + time_left
    
func set_by_time_left(aux_left, shield_left, meter_left):
    print("Setting by time left")
    print("aux_left: " + str(aux_left))
    print("shield_left: " + str(shield_left))
    print("meter_left: " + str(meter_left))    
    time_left = aux_left
    time_timeout = OS.get_unix_time() + shield_left + meter_left + aux_left
    print("time_left: " + str(time_left))
    print("time_timeout: " + str(time_timeout))
    
func set_by_end_time(aux_end, meter_end):
    print("Setting by end time")
    print("aux_end: " + str(aux_end))
    print("meter_end: " + str(meter_end))
    time_left = max(0, int(aux_end - meter_end))
    time_timeout = aux_end
    print("time_left: " + str(time_left))
    print("time_timeout: " + str(time_timeout))

# Called when the node enters the scene tree for the first time.
func _ready():
    print("In ready:")
    started = false
    text = ""
    time_timeout = OS.get_unix_time() + time_left
    running = false
    print("time_timeout: " + str(time_timeout))
    
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    if running and started:
        time_timeout = max(0, time_timeout - OS.get_unix_time()) # + time_offset))
        tsecs = 10 - (OS.get_system_time_msecs()/100 % 10) - 1
        if tsecs == 0:
            if not at0:
                play_tick()
            at0 = true
        else:
            at0 = false
        update_display()
        if time_left == 0 and tsecs == 0:
            running = false
            emit_signal("out_of_aux_time")
            
func play_tick():
    $ticks.get_children()[1].play()
    #randi() % ($ticks.get_child_count() - 1)

func start_timer():
#    request_unix_time()
    time_timeout = OS.get_unix_time() + time_left
    $SoundAnimator.play("HumOn")
    $Hum.play()
    running = true

func stop_timer():
    add_time()
    time_timeout = time_left + OS.get_unix_time() # + time_offset)
    $SoundAnimator.play("HumOff")
    $OffTimer.start()
#    request_unix_time()
    running = false

func add_time():
    time_left += increase_by

func update_display():
    var seconds_tenths = str(tsecs)
    var seconds = str(int(time_left) % 60)
    if len(seconds) == 1:
        seconds = "0" + seconds
    var minutes = str(int(time_left / 60) % 60)
    if len(minutes) == 1:
        minutes = "0" + minutes
    var hours = str(int(time_left / (60 * 60)))
    if len(hours) == 1:
        hours = "0" + hours
    text = hours + ":" + minutes + ":" + seconds + "." + seconds_tenths
    
#func request_unix_time():
#    $HTTPRequest.request("http://worldtimeapi.org/api/timezone/Etc/UTC")

#func _on_HTTPRequest_request_completed(_result, response_code, _headers, body):
#    if response_code == 200:
#        var json = JSON.parse(body.get_string_from_utf8())
#        time_offset = int(json.result['unixtime']) - OS.get_unix_time()
#        print("Offset: %s" % time_offset)

func _on_Meter_out_of_time():
    start_timer()


func _on_OffTimer_timeout():
    $Hum.stop()
