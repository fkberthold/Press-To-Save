extends Label

var prize_value = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    text = ""

func comma_sep(n: int) -> String:
    var result := ""
    var i: int = abs(n)

    while i > 999:
        result = ",%03d%s" % [i % 1000, result]
        i /= 1000

    return "%s%s%s" % ["-" if n < 0 else "", i, result]

func get_prize_value():
    return prize_value

func update_display():
    text = "$" + comma_sep(prize_value)

func _on_DefenceSystem_update_reward(reward):
    prize_value = reward
    text = "$" + comma_sep(prize_value)
