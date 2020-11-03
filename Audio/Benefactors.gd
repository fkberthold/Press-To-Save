extends ItemList


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#var heros = ["inkVVoVVweaver", "Kaprekar", "Jim", "Tony", "Josie", "LytheSD", "Cris", "Ellen", "Mom", "Dragon"]
#var rewards = ["$10000", "$8842", "$5384", "$3284", "$2844", "$700", "$500", "$200", "$100", "$5"]
var rewards = {}

# Called when the node enters the scene tree for the first time.
func _ready():
    update_board()
        
func update_board():
    clear()
    var hero_reward_pairs = rewards_to_sorted_pairs()
    for hero_reward in hero_reward_pairs:
        if hero_reward[1] == 0:
            continue
        var hero = hero_reward[0]
        var reward =  " ".repeat(int(max(0, 15 - len(hero)))) + "$" + str(hero_reward[1])
        add_item(hero + reward, null, false)

class RewardSorter:
    static func sort_reward(a, b):
        if a[1] > b[1]:
            return true
        return false

func rewards_to_sorted_pairs():
    var reward_array = []
    for key in rewards:
        reward_array.push_back(rewards[key])
    reward_array.sort_custom(RewardSorter, "sort_reward")
    return reward_array
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
