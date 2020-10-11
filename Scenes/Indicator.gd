extends Node2D

export(Color, RGB) var off_color
export(Color, RGB) var on_color
export(String, MULTILINE) var text
export(int) var value_below

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var is_on = false
var last_time = 0


# Called when the node enters the scene tree for the first time.
func _ready():
    $InfoLabel.text = text
    $LightBox.color = off_color
    is_on = false
    if Engine.editor_hint:
        $OnSound.volume_db = -100
        $OffSound.volume_db = -100

func turn_on():
    if !is_on:
        $LightBox.color = on_color
        $OnSound.play()
        is_on = true

func turn_off():
    if is_on:
        $LightBox.color = off_color
        $OffSound.play()
        is_on = false

func _on_DefenceSystem_update_shield(charging, time_left, percent_left):
    if time_left and not charging and time_left < value_below:
        turn_on()
    else:
        turn_off()
