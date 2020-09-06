extends Node2D

signal button_down

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const downShift = 0.95


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass


func _on_ShieldButton_button_down():
    scale *= downShift
    emit_signal("button_down")

func _on_ShieldButton_button_up():
    scale /= downShift
