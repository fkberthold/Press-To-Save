extends RichTextLabel

export var display_speed = 5
export var chars_to_display = 69
export var standard_color = Color("#10710c")
export var alert_color = Color("#10cf0c")
export var news_color = Color("#10710c")

var rng = RandomNumberGenerator.new()
var last_chosen = 0
var new_string = true
var current_strings = [[standard_color, "Initiating Connection..."]]

var ticker_talk = []
var started # Have we connected to the network?
var active # Is there power

func select_random_string():
    var next_number = rng.randi_range(0, len(ticker_talk) - 2)
    if next_number < last_chosen:
        last_chosen = next_number
    else:
        last_chosen = next_number + 1
    
    return [standard_color, "   " + ticker_talk[last_chosen]]

# Called when the node enters the scene tree for the first time.
func _ready():
    var f = File.new()
    f.open("res://one_liners.tres", f.READ)
    while not f.eof_reached():
        ticker_talk.append(f.get_line())
    active = false
    rng.randomize()
    last_chosen = -1
    bbcode_text = " ".repeat(chars_to_display)
    $Timer.wait_time = 1.0/display_speed
    $Timer.start()
    

func add_alert(message):
    current_strings.append([alert_color, "   " + message])

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func strip_bb(txt):
    var re = RegEx.new()
    re.compile("\\[.+?\\]")
    return re.sub(txt, "", true)
    
func remove_first_char(txt):
    var re = RegEx.new()
    var tag = ""
    re.compile("\\[.+?\\]")
    if len(txt) == 0:
        return txt
    if txt[0] == "[":
        tag = re.search(txt).get_string()
        txt = re.sub(txt, "")
    if len(txt) > 0:
        txt = txt.substr(1)
        if len(txt) > 0 and txt[0] != "[":
            txt = tag + txt
    return txt

func _on_Timer_timeout():
    if new_string:
        bbcode_text += "[color=#" + current_strings[0][0].to_html(false) + "]"
        new_string = false
    bbcode_text += current_strings[0][1][0]
    current_strings[0][1] = current_strings[0][1].substr(1)
#    if len(strip_bb(bbcode_text)) > chars_to_display:
    if get_font("normal_font").get_string_size(bbcode_text).x > rect_size.x:
        bbcode_text = remove_first_char(bbcode_text)
    if len(current_strings[0][1]) == 0:
        current_strings.pop_front()
        new_string = true
    if len(current_strings) == 0 and started and active:
        current_strings.append(select_random_string())
    elif len(current_strings) == 0 and not started:
        current_strings.append([standard_color, " Initiating Connection..."])
    elif len(current_strings) == 0 and not active:
        current_strings.append([standard_color, " Press the Red 'Power Shield' Button to activate the Lunar Defence System."])


func _on_DefenceSystem_update_aux(running, time_left):
    started = true


func _on_DefenceSystem_update_shield(charging, time_left, percent_left):
    pass # Replace with function body.
