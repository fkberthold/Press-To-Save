extends Label

var reward = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    text = "$" + comma_sep(reward)


func comma_sep(n: int) -> String:
    var result := ""
    var i: int = abs(n)

    while i > 999:
        result = ",%03d%s" % [i % 1000, result]
        i /= 1000

    return "%s%s%s" % ["-" if n < 0 else "", i, result]

func add_reward(value: int):
    reward += value
    text = "$" + comma_sep(reward)

func set_reward(value: int):
    reward = value
    text = "$" + comma_sep(reward)
    
