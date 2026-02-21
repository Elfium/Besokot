extends Control

@onready var room: Control = %room
@onready var blackout: ColorRect = %Blackout
@onready var dialog_box: Control = %dialog_box

var dialogue_focus : bool = false

@onready var reward_node : PackedScene = preload("uid://mhpurlc7aalx")

func _ready() -> void:
	Global.show_dialogue.connect(focus_dialogue)
	Global.hide_dialogue.connect(focus_room)
	Global.give_reward.connect(get_reward)
	room.scale = Vector2(0,0)
	blackout.modulate.a = 1
	dialog_box.scale.y = 0
	await get_tree().create_timer(1).timeout
	blackout_animation()
	await get_tree().create_timer(0.5).timeout
	room_start_animation()
	await get_tree().create_timer(2).timeout
	Global.current_dialogue_key = "intro"
	Global.show_dialogue.emit("intro")

func room_start_animation() -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(room,"scale",Vector2(1,1),2).from(Vector2(0,0)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(room,"modulate:a",1,2).from(0)

func blackout_animation() -> void:
	var tween = create_tween()
	tween.tween_property(blackout,"modulate:a",0,1).from(1)

# Add parameter even if you don't use it
func focus_dialogue(dialogue_key: String = "") -> void:
	var tween = create_tween()
	tween.tween_property(room,"modulate:a",1,0.5)
	

func focus_room() -> void:
	var tween = create_tween()
	tween.tween_property(room,"modulate:a",1,0.5)
	
	

func get_reward() -> void:
	var reward = reward_node.instantiate()
	self.add_child(reward)
	print("works")
