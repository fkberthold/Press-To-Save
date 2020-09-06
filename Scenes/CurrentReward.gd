extends Label

export var initial_max = 5
#export var max_increment = 2
var current_max = initial_max
var prize_value = 0
var stored_value = 0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var running = false
var started = false


# Called when the node enters the scene tree for the first time.
func _ready():
    text = ""

func _process(_delta):
    pass

func comma_sep(n: int) -> String:
    var result := ""
    var i: int = abs(n)

    while i > 999:
        result = ",%03d%s" % [i % 1000, result]
        i /= 1000

    return "%s%s%s" % ["-" if n < 0 else "", i, result]

#func increment_max():
#    current_max += max_increment
func set_new_max():
    var quarter = current_max/4
    if (quarter * 3) >= prize_value:
        current_max = int(current_max + (current_max - prize_value) / 4)
    else:
        current_max = int(max(2, current_max - (prize_value / 4)))

func set_prize_value(percent, time):
    if time < 5:
        prize_value = stored_value + round(ease(percent, 0.4) * current_max * 2)
    else:
        prize_value = stored_value + round(ease(percent, 0.4) * current_max)

func get_prize_value():
    return prize_value

func update_display():
    text = "$" + comma_sep(prize_value)
    
func _on_Meter_out_of_time():
    current_max = initial_max
    prize_value = 0
    update_display()

func _on_Meter_percent_left(percent, time):
    set_prize_value(1 - percent, time)
    update_display()
