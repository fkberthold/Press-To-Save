extends RichTextLabel

export var display_speed = 5
export var chars_to_display = 69
export var standard_color = Color("#10710c")
export var alert_color = Color("#10cf0c")
export var news_color = Color("#10710c")

var rng = RandomNumberGenerator.new()
var news_ready = true
var last_chosen = 0
var new_string = true
var alert_strings = []
var current_strings = []

var ticker_talk = []
var started # Have we connected to the network?
var active # Is there power
var alert = false
var string_buffer
var alert_buffer = ""
var blink_on = 1

func select_random_string():
    var next_number = rng.randi_range(0, len(ticker_talk) - 2)
    if next_number < last_chosen:
        last_chosen = next_number
    else:
        last_chosen = next_number + 1
    
    return add_message(ticker_talk[last_chosen])

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

func add_message(message):
    current_strings.append([standard_color, " -- " + message])
    
func add_alert(message):
    alert_strings.append([alert_color, message])
    
func add_news():
    var news = generate_news()
    current_strings.append([news_color, " !! " + news])
    
func generate_news():
    var locations = ["L-City", "Tyco Under", "Old Dome", "Luna Authority Complex", "Hong Kong Luna",
                 "Johnson City", "Novylen", "New Mumbai"]
    var good_events = ["%s to Build Statue to Luna's Defenders", "New Shop Opening in %s", "Rebuilding underway in %s",
                   "%s's success continues to grow", "Hero returns home to %s", "New public school opens in %s"]
    var bad_events = ["Minor leak found in %s", "Robbery in %s", "Food shortages in %s causing concern"]
    var location = locations[rng.randi_range(0, len(locations) - 2)]
    var event = ""
    if rng.randi_range(0, 10) < 2:
        event = bad_events[rng.randi_range(0, len(bad_events) - 2)]
    else:
        event = good_events[rng.randi_range(0, len(good_events) - 2)]
    return event % location

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

func ticker_display():
    if new_string:
        bbcode_text += "[color=#" + current_strings[0][0].to_html(false) + "]"
        new_string = false
    bbcode_text += current_strings[0][1][0]
    current_strings[0][1] = current_strings[0][1].substr(1)
#    if len(strip_bb(bbcode_text)) > chars_to_display:
    if get_font("normal_font").get_string_size(bbcode_text).x > rect_size.x:
        bbcode_text = remove_first_char(bbcode_text)
        
func center_display():
    alert = true
    string_buffer = bbcode_text
    var next_alert = alert_strings.pop_front()
    bbcode_text = "[color=#" + next_alert[0].to_html(false) + "]"
    bbcode_text += next_alert[1]
    if chars_to_display > len(next_alert[1]):
        bbcode_text = " ".repeat(int((chars_to_display - len(next_alert[1])) / 2)) + bbcode_text
    alert_buffer = bbcode_text
    $AlertTimer.wait_time = (1.0/display_speed) * len(next_alert[1])
    $AlertTimer.start()
    
func _on_Timer_timeout():
    if len(current_strings) == 0 and not started and len(alert_strings) == 0 and not alert:
        add_alert("Initiating Connection...")
    elif len(current_strings) == 0 and not active and len(alert_strings) == 0 and not alert:
        add_alert("Press the Red 'Power Shield' Button")
    if alert_strings and not alert:
        center_display()
        return
    if alert:
        if blink_on:
            bbcode_text = alert_buffer
        else:
            bbcode_text = ""
        blink_on = (blink_on + 1) % 8
        return
    if current_strings and len(current_strings[0][1]) == 0:
        current_strings.pop_front()
        new_string = true
    if len(current_strings) == 0 and started and active:
        if rng.randi_range(0, 10) < 2 and news_ready:
            news_ready = false
            add_news()
        else:
            news_ready = true
            select_random_string()
    ticker_display()



func _on_DefenceSystem_update_aux(_running, _time_left):
    started = true


func _on_DefenceSystem_update_shield(_charging, _time_left, _percent_left):
    pass # Replace with function body.


func _on_AlertTimer_timeout():
    alert = false
    bbcode_text = string_buffer
