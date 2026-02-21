extends Control

@onready var dialogue_button : Button = %dialogue_button
@onready var dialogue_name_panel: Panel = %dialogue_name_panel
@onready var besokot_head: AnimatedSprite2D = %Besokot_Head
@onready var besokot_body: AnimatedSprite2D = %Besokot_Body
@onready var besokot_face: AnimatedSprite2D = %Besokot_Face
@onready var dialogue_text: RichTextLabel = %dialogue_text
@onready var choice_container: VBoxContainer = %choice_container
@onready var dialogue_sfx: AudioStreamPlayer = %dialogue_sfx
@onready var dialogue_click: AudioStreamPlayer = %dialogue_click
@onready var loose_sfx: AudioStreamPlayer = %loose_sfx
@onready var win_sfx: AudioStreamPlayer = %win_sfx
@onready var harp_sfx: AudioStreamPlayer = %harp_sfx




@onready var choice_button : PackedScene = preload("uid://b6r7202qxmsch")

var is_typing: bool = false
var current_line_has_choices: bool = false
var is_dialogue_active: bool = false
var is_closing: bool = false

# Переменные для игры
var rps_mode: bool = false
var rps_waiting_for_result: bool = false

# Для звука печати
var typing_timer: Timer
var chars_per_sound: int = 4  # Play sound every 4 characters

func _ready() -> void:
	besokot_animation_idle()
	dialogue_text.visible = false
	dialogue_text.text = ""
	choice_container.visible = false
	dialogue_button.disabled = false
	scale.y = 0
	
	Global.show_dialogue.connect(_on_show_dialogue)
	Global.hide_dialogue.connect(_on_hide_dialogue)
	
	# Create timer for typing sound
	typing_timer = Timer.new()
	typing_timer.wait_time = 0.05  # Constant interval
	typing_timer.autostart = false
	typing_timer.one_shot = false
	typing_timer.timeout.connect(_play_dialogue_sfx)
	add_child(typing_timer)

func _on_show_dialogue(dialogue_key: String = "") -> void:
	if is_closing:
		await dialogue_end_animation()
	
	is_dialogue_active = true
	is_closing = false
	rps_mode = false
	rps_waiting_for_result = false
	
	if dialogue_key == "":
		dialogue_key = "intro"
	
	# Если начинаем игру с самого начала, сбрасываем счет
	if dialogue_key == "rps_game":
		Global.reset_rps_game()
	
	# Если начинаем игру заново после поражения, счет уже сброшен в rps_restart
	if dialogue_key == "rps_restart":
		Global.reset_rps_game()
	
	Global.current_dialogue_key = dialogue_key
	Global.current_line_index = 0
	
	dialogue_text.visible = true
	dialogue_text.text = ""
	dialogue_text.visible_ratio = 0.0
	choice_container.visible = false
	dialogue_button.disabled = false
	
	dialogue_start_animation()
	await get_tree().create_timer(0.3).timeout
	
	show_current_line()

func dialogue_start_animation() -> void:
	scale.y = 0
	self.modulate.a = 1
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale:y", 1, 0.5)

func dialogue_end_animation() -> void:
	is_closing = true
	dialogue_button.disabled = true
	
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "scale:y", 0, 0.2)
	tween.tween_property(self, "modulate:a", 0, 0.2)
	await tween.finished
	
	is_closing = false
	dialogue_button.disabled = false

func _on_hide_dialogue() -> void:
	# Проверяем ключ ДО того, как его обнулят
	var was_victory = (Global.current_dialogue_key == "rps_victory")
	print("_on_hide_dialogue: was_victory = ", was_victory)
	
	dialogue_text.visible = false
	dialogue_text.text = ""
	choice_container.visible = false
	dialogue_button.disabled = false
	besokot_animation_idle()
	is_dialogue_active = false
	rps_mode = false
	rps_waiting_for_result = false
	
	# Если это победа - испускаем сигнал
	if was_victory:
		print("🎮 ПОБЕДА! Испускаем сигнал give_reward")
		Global.give_reward.emit()
		harp_sfx.play()

func show_current_line() -> void:
	if rps_waiting_for_result:
		show_rps_result()
		return
	
	var dialogue_data = Global.dialogues.get(Global.current_dialogue_key, {})
	var lines = dialogue_data.get("lines", [])
	
	if Global.current_line_index < lines.size():
		# ПРИНУДИТЕЛЬНО очищаем и включаем текст
		dialogue_text.text = ""
		dialogue_text.visible = true
		dialogue_text.modulate.a = 1.0
		choice_container.visible = false
		
		# Подставляем счет в строку если нужно
		var current_text = lines[Global.current_line_index]
		if "{0}" in current_text and "{1}" in current_text:
			current_text = current_text.replace("{0}", str(Global.rps_player_score)).replace("{1}", str(Global.rps_opponent_score))
		
		dialogue_text.text = current_text
		dialogue_text.visible_ratio = 0.0
		
		var is_last_line = Global.current_line_index == lines.size() - 1
		current_line_has_choices = is_last_line and dialogue_data.get("choices", []).size() > 0
		
		animate_dialogue_line()
		Global.current_line_index += 1
	else:
		# Если это rps_intro и реплики закончились - переходим к игре
		if Global.current_dialogue_key == "rps_intro":
			print("Переход от rps_intro к rps_game")
			Global.current_dialogue_key = "rps_game"
			Global.current_line_index = 0
			show_current_line()
			return
		
		# Если это rps_defeat и реплики закончились - переходим к рестарту
		if Global.current_dialogue_key == "rps_defeat":
			print("Переход от rps_defeat к rps_restart")
			Global.reset_rps_game()
			Global.current_dialogue_key = "rps_restart"
			Global.current_line_index = 0
			show_current_line()
			return
		
		# Если это rps_victory и реплики закончились - завершаем
		if Global.current_dialogue_key == "rps_victory":
			print("Победа! Все реплики показаны, завершаем диалог")
			# Сигнал вызовется в _on_hide_dialogue
			complete_dialogue()
			return
		
		complete_dialogue()

func animate_dialogue_line() -> void:
	# Force visibility
	dialogue_text.visible = true
	dialogue_text.modulate.a = 1.0
	
	# Get current text length
	var current_text_length = len(dialogue_text.text)
	
	# Calculate how many sounds to play (one every 4 characters)
	var total_sounds_needed = ceil(current_text_length / float(chars_per_sound)) * 2
	
	# CONSTANT interval between sounds (0.2 seconds)
	typing_timer.wait_time = randf_range(0.14,0.2)
	
	
	# If text is already visible, don't animate again
	if dialogue_text.visible_ratio >= 1.0:
		is_typing = false
		if current_line_has_choices:
			show_choices()
		else:
			dialogue_button.disabled = false
		return
	
	is_typing = true
	dialogue_button.disabled = true
	dialogue_text.visible_ratio = 0.0
	
	# Start sound timer with constant interval
	if total_sounds_needed > 2:
		typing_timer.start()
	
	var tween = create_tween()
	tween.tween_property(dialogue_text, "visible_ratio", 1, 0.5).from(0.0)
	
	await tween.finished
	
	# Stop timer
	typing_timer.stop()
	
	is_typing = false
	
	if current_line_has_choices:
		show_choices()
	else:
		dialogue_button.disabled = false

func _play_dialogue_sfx() -> void:
	if dialogue_sfx and is_typing:
		dialogue_sfx.pitch_scale = randf_range(0.95,1.1)
		dialogue_sfx.play()

func show_choices() -> void:
	var dialogue_data = Global.dialogues.get(Global.current_dialogue_key, {})
	var choices = dialogue_data.get("choices", [])
	
	for child in choice_container.get_children():
		child.queue_free()
	
	if choices.size() > 0:
		choice_container.visible = true
		dialogue_button.disabled = true
		
		for choice in choices:
			var button = choice_button.instantiate()
			button.text = choice.text
			button.pressed.connect(_on_choice_selected.bind(choice.next))
			choice_container.add_child(button)
	else:
		dialogue_button.disabled = false

func _on_choice_selected(next_dialogue_key: String) -> void:
	dialogue_click.pitch_scale = randf_range(0.9,1.1)
	dialogue_click.play()
	# Обработка выбора в игре КНБ
	if Global.current_dialogue_key == "rps_game" or Global.current_dialogue_key == "rps_restart":
		var player_choice = ""
		
		for child in choice_container.get_children():
			if child is Button and child.pressed.is_connected(_on_choice_selected):
				if "Камень" in child.text:
					player_choice = "камень"
				elif "Ножницы" in child.text:
					player_choice = "ножницы"
				elif "Бумага" in child.text:
					player_choice = "бумага"
				break
		
		# Играем в раунд
		Global.play_rps(player_choice)
		rps_waiting_for_result = true
		
		# Показываем результат
		Global.current_dialogue_key = Global.get_rps_result_key()
		Global.current_line_index = 0
		choice_container.visible = false
		dialogue_button.disabled = false
		show_current_line()
		return
	
	# Отмечаем анекдот как просмотренный
	if next_dialogue_key == "Хочу анекдот!":
		Global.mark_dialogue_seen("Хочу анекдот!")
	
	# Отмечаем обычные диалоги как просмотренные
	var dialogue_keys_to_mark = ["Календарь", "Цветок", "Кровать", "Шкаф", "Картина", "Книги"]
	if next_dialogue_key in dialogue_keys_to_mark:
		Global.mark_dialogue_seen(next_dialogue_key)
	
	choice_container.visible = false
	dialogue_button.disabled = false
	besokot_animation_active()
	
	if next_dialogue_key == "end":
		complete_dialogue()
	else:
		Global.current_dialogue_key = next_dialogue_key
		Global.current_line_index = 0
		rps_waiting_for_result = false
		show_current_line()

func show_rps_result() -> void:
	rps_waiting_for_result = false
	
	# Показываем результат раунда
	var result_text = ""
	
	result_text = "Ты выбрала: " + Global.rps_player_choice + "\n"
	result_text += "Бесокот выбрал: " + Global.rps_opponent_choice + "\n\n"
	
	match Global.rps_result:
		"победа":
			result_text += "[color=#a5d6a5]Ты выиграла раунд![/color]"
		"поражение":
			result_text += "[color=#ffb3b3]Я выиграл раунд![/color]"
		"ничья":
			result_text += "[color=#ffd966]Ничья![/color]"
	
	result_text += "\n\nСчет {0} : {1}".format([Global.rps_player_score, Global.rps_opponent_score])
	
	dialogue_text.text = result_text
	dialogue_text.visible_ratio = 0.0
	animate_dialogue_line()
	
	# Проверяем, закончена ли игра
	if Global.is_rps_game_finished():
		await get_tree().create_timer(1.0).timeout
		
		# ЖДЕМ НАЖАТИЯ КНОПКИ перед показом финальных реплик
		# Устанавливаем флаг, что нужно показать финальный диалог при следующем нажатии
		if Global.is_rps_player_victorious():
			Global.current_dialogue_key = "rps_victory"
			Global.current_line_index = 0
			
			# НЕ вызываем show_current_line сразу!
			# Просто меняем ключ и ждем нажатия кнопки
			
		elif Global.is_rps_player_defeated():
			Global.current_dialogue_key = "rps_defeat"
			Global.current_line_index = 0
			# НЕ вызываем show_current_line сразу!
			# Просто меняем ключ и ждем нажатия кнопки

func _on_dialogue_button_pressed() -> void:
	if dialogue_button.disabled or is_closing:
		return
	dialogue_click.pitch_scale = randf_range(0.9,1.1)
	dialogue_click.play()
	# Принудительно исправляем, если is_dialogue_active сброшен
	if not is_dialogue_active and Global.current_dialogue_key != "":
		is_dialogue_active = true
		
	var tween = create_tween().set_parallel()
	tween.tween_property(dialogue_button, "scale", Vector2(1,1), 0.15).from(Vector2(1.2,0.8))
	tween.tween_property(dialogue_name_panel, "size:y", 100, 0.15).from(130)
	tween.tween_property(dialogue_button, "modulate", Color(1,1,1), 0.15).from(Color(2,2,2))
	besokot_animation_active()
	
	# Если это результат раунда и игра не закончена - переходим к следующему раунду
	if Global.current_dialogue_key in ["rps_win", "rps_lose", "rps_draw"] and not Global.is_rps_game_finished():
		Global.current_dialogue_key = "rps_game"
		Global.current_line_index = 0
		show_current_line()
		return
	
	var dialogue_data = Global.dialogues.get(Global.current_dialogue_key, {})
	var lines = dialogue_data.get("lines", [])
	
	if Global.current_line_index >= lines.size() and not current_line_has_choices and not rps_waiting_for_result:
		# Проверяем особые случаи
		if Global.current_dialogue_key == "rps_intro":
			Global.current_dialogue_key = "rps_game"
			Global.current_line_index = 0
			show_current_line()
		elif Global.current_dialogue_key == "rps_defeat":
			Global.reset_rps_game()
			Global.current_dialogue_key = "rps_restart"
			Global.current_line_index = 0
			show_current_line()
		else:
			end_dialogue_with_animation()
	else:
		show_current_line()

func end_dialogue_with_animation() -> void:
	# СОХРАНЯЕМ ключ ДО анимации
	var victory_key = Global.current_dialogue_key
	print("end_dialogue: сохраненный ключ = ", victory_key)
	
	await dialogue_end_animation()
	
	# Проверяем сохраненный ключ
	if victory_key == "rps_victory":
		print("🎮 ПОБЕДА! Испускаем сигнал give_reward")
		harp_sfx.play()
		Global.give_reward.emit()
	
	Global.current_dialogue_key = ""
	Global.current_line_index = 0
	besokot_animation_idle()
	is_dialogue_active = false
	rps_mode = false
	rps_waiting_for_result = false
	
	dialogue_text.visible = false
	dialogue_text.text = ""
	choice_container.visible = false
	dialogue_button.disabled = false
	
	Global.hide_dialogue.emit()

func complete_dialogue() -> void:
	# Проверяем, был ли это диалог победы ДО того, как обнулим ключ
	var was_victory = (Global.current_dialogue_key == "rps_victory")
	
	# Для отладки
	print("complete_dialogue: current_key = ", Global.current_dialogue_key)
	print("complete_dialogue: was_victory = ", was_victory)
	
	# Очищаем все
	Global.current_dialogue_key = ""
	Global.current_line_index = 0
	besokot_animation_idle()
	is_dialogue_active = false
	rps_mode = false
	rps_waiting_for_result = false
	
	dialogue_text.visible = false
	dialogue_text.text = ""
	choice_container.visible = false
	dialogue_button.disabled = false

# Animation functions
func besokot_animation_idle() -> void:
	var tween_head = create_tween().set_loops()
	var tween_body = create_tween().set_loops()
	var tween_face = create_tween().set_loops()
	tween_head.tween_property(besokot_head, "position:y", 15, 0.5)
	tween_head.tween_property(besokot_head, "position:y", 0, 0.5)
	tween_body.tween_property(besokot_body, "scale:x", 1.1, 0.5)
	tween_body.tween_property(besokot_body, "scale:x", 1, 0.5)
	tween_face.tween_property(besokot_face, "position:y", 105, 0.5)
	tween_face.tween_property(besokot_face, "position:y", 100, 0.5)
	
func besokot_animation_active() -> void:
	var tween_head = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tween_body = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tween_face = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_head.tween_property(besokot_head, "scale:y", 1, 0.5).from(1.2)
	tween_body.tween_property(besokot_body, "scale:y", 1, 0.5).from(1.2)
	tween_face.tween_property(besokot_face, "scale:y", 1, 0.5).from(1.1)
