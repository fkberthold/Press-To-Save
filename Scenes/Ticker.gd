extends Label

export var display_speed = 5
export var chars_to_display = 65

var rng = RandomNumberGenerator.new()
var last_chosen = 0
var current_strings = ["Initiating Connection..."]

var ticker_talk = ["Waiting1", "Waiting2"]
var started

func select_random_string():
    var next_number = rng.randi_range(0, len(ticker_talk) - 2)
    if next_number < last_chosen:
        last_chosen = next_number
    else:
        last_chosen = next_number + 1
    
    return ticker_talk[last_chosen]

# Called when the node enters the scene tree for the first time.
func _ready():
    started = false
    rng.randomize()
    last_chosen = -1
    text = " ".repeat(chars_to_display)
    $Timer.wait_time = 1.0/display_speed
    $Timer.start()

func add_message(message):
    current_strings.append(message)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_Timer_timeout():
    text += current_strings[0][0]
    current_strings[0] = current_strings[0].substr(1)
    if len(text) > chars_to_display:
        text = text.substr(1)
    if len(current_strings[0]) == 0:
        current_strings.pop_front()
    if len(current_strings) == 0 and started:
        current_strings.append(" " + select_random_string())
    elif len(current_strings) == 0 and not started:
        current_strings.append(" Initiating Connection...")
