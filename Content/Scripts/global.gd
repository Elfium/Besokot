extends Node

var current_dialogue_key = ""
var current_line_index = 0
var current_choices = []

# Переменные для игры в камень-ножницы-бумага
var rps_player_choice: String = ""
var rps_opponent_choice: String = ""
var rps_result: String = ""
var rps_player_score: int = 0
var rps_opponent_score: int = 0
var rps_max_score: int = 5
var rps_game_active: bool = false
var rps_has_won_once: bool = false

# Флаги для отслеживания просмотренных диалогов
var seen_calendar: bool = false
var seen_flower: bool = false
var seen_bed: bool = false
var seen_wardrobe: bool = false
var seen_painting: bool = false
var seen_books: bool = false
var seen_rps_intro: bool = false

var dialogues = {
	"intro": {
		"lines": [
			"Эй ты, странное существо!",
			"Кто ты?",
			"И как ты сюда вообще попала...",
			"[shake rate=20 level=10][color=#ffc485]Дурында[/color][/shake]."
		],
		"choices": [
			{
				"text": "Я - Маша!",
				"next": "Сказать имя"
			},
			{
				"text": "Ты сам вообще кто?",
				"next": "Не Сказать имя"
			}
		]
	},
	"Сказать имя": {
		"lines": [
			"Маша? да...да...точно...",
			"Это тебе мне сказали кое-что передать...",
			"Но сейчас не об этом.",
			"Я - Бесокот. А это мой дом, так что не топчись тут без дела!",
			"Можешь осмотреться, но сильно не лазь по моим вещам... у меня их и так не много.",
			"Видишь ли, мой создатель не успел нарисовать мне больше.",
			"А я говорил ему - поставь мне водные горки и ларёк у кровати...",
			"[shake rate=20 level=10][color=#ffc485]Я ГОВОРИЛ ЕМУ !!![/color][/shake]",
			"А, Кстати! Возможно некоторые вещи тебе покажутся жутко знакомыми...",
			"Не обращай внимания.",
			"Эта вселенная существует паралельно твоей, слышала ли ты что-то про теорию струн?",
			"Конечно нет, [shake rate=20 level=10][color=#ffc485]глупень[/color][/shake].",
			"Ладно, не трать мое время и сама найди то, что тебе оставили.",
		],
	},
	"Не Сказать имя": {
		"lines": [
			"Я Бесокот, [shake rate=20 level=10][color=#ffc485]болванишка[/color][/shake], и я здесь задаю вопросы!",
			"Так что повторюсь, [shake rate=20 level=10]кто ты?[/shake]"
		],
		"choices": [
			{
				"text": "Я - Маша!",
				"next": "Сказать имя"
			},
			{
				"text": "Ты сам вообще кто?",
				"next": "Не Сказать имя"
			}
		]
	},
	"Календарь": {
		"lines": [
			"На вид самый обыкновенный календарь...",
			"Хмм...",
			"Помечена какая-то важная дата...",
			"Что же она может значить..."
		],
		"choices": []
	},
	"Цветок": {
		"lines": [
			"Какой большой цветок...",
			"Говорят девушкам нравятся цветы?",
			"Ну что, ты уже готова чесать мне за ухом?",
			"Еще нет?",
		],
		"choices": []
	},
	"Кровать": {
		"lines": [
			"Моя гордость!",
			"Моя кровать!",
			"После каждого сна на ней образуется ковёр из моей шерсти...",
			"Ха-Ха, где-то через пол года я буду спать уже на втором этаже.",
			"...",
			"Хмм... у меня ведь раньше небыло кровати...",
			"Странно... я ведь всегда спал в этом углу...",
			"Откуда она вообще появилась..."
		],
		"choices": []
	},
	"Шкаф": {
		"lines": [
			"Мой единственный шкаф!",
			"Кто-то положил руководство по закваске капусты на верхнюю полку...",
			"Они даже не подумали о том, как мне её оттуда достать!",
			"[shake rate=20 level=10][color=#ffc485]БЕСТОЛОЧИ !!![/color][/shake]",
			"Капуста должна дать сок!",
			"[shake rate=20 level=10][color=#ffc485]ДАТЬ СОК !!![/color][/shake]",
		],
		"choices": []
	},
	"Картина": {
		"lines": [
			"Какая...странная картина.",
			"Мне кажется автор изобразил на ней кого-то очень для него важного.",
			"...",
			"Если принюхаться, можно почувстовать запах красок, природы и лета.",
			"Кто вообще будет хранить у себя такие...странные... рисунки."
		],
		"choices": []
	},
	"Книги": {
		"lines": [
			"Куча разных книг.",
			"Наверное там написано что-то интересное...",
			"Как жаль, что каждый раз когда я хочу перевернуть первую страницу...",
			"Она просто рвётся от моих когтей...",
			"Эх... знать бы что там на второй странице в книге анекдотов...",
			"Но я могу рассказать парочку с первой!",
		],
		"choices": [
			{
				"text": "Хочу анекдот!",
				"next": "Хочу анекдот!"
			},
			{
				"text": "Не стоит.",
				"next": "Не Хочу анекдот"
			}
		]
	},
	"Хочу анекдот!": {
		"lines": [
			"Хе-Хе, я так и думал!",
			"Вот, как тебе этот...",
			"Вечеринка животных.",
			"Все пьяные, смеются, танцуют и тут на сцену выходит хамелеон:",
			"Смотрите что могу... и меняет цвет - кто повторит? ",
			"Тут из толпы голос осьминога:",
			"Подержите мое пиво",
			"Подержите мое пиво",
			"Подержите мое пиво",
			"Подержите мое пиво",
			"Подержите мое пиво",
			"Подержите мое пиво",
			"Подержите мое пиво",
			"[shake rate=20 level=10][color=#ffc485]Подержите мое пиво[/color][/shake]",
			"...",
			"Вот еще, слушай!",
			"Жил-был царь.",
			"Было у царя косоглазие.",
			"Состарился он и решит пойти питушествовать куда глаза глядят. ",
			"Пошел...",
			"[shake rate=20 level=10][color=#ffc485]И порвался нахер!!![/color][/shake]",
			"...",
			"Остальные были на второй странице..."
		],
	},
	"Не Хочу анекдот": {
		"lines": [
			"Ну как хочешь...",
			"Может в другой раз."
		],
		"choices": []
	},
	"rps_intro": {
		"lines": [
			"Ну  что, нашла что-то?",
			"Ха-Ха, конечно нет.",
			"То, что тебе просили передать вседа было при мне.",
			"Честно говоря просто люблю шкодничать.",
			"Хмм...Давай так...",
			"Как насчёт...",
			"Камень, Ножницы, Бумага?",
			"И до [shake rate=20 level=10][color=#ffc485]5[/color][/shake] побед",
			"Если выиграешь меня...",
			"Так уж и быть отдам тебе твой подарок.",
			"[shake rate=20 level=10][color=#ffc485]Начинаем![/color][/shake]"
		],
		"choices": []  # Нет выбора, сразу начинаем игру
	},
	"rps_game": {
		"lines": [
			"Счет {0} : {1}",
			"Выбирай!"
		],
		"choices": [
			{
				"text": "Камень",
				"next": "rps_play"
			},
			{
				"text": "Ножницы",
				"next": "rps_play"
			},
			{
				"text": "Бумага",
				"next": "rps_play"
			}
		]
	},
	"rps_play": {
		"lines": [],  # Будет заполнено динамически
		"choices": []  # Пустой массив - нет выборов!
	},
	"rps_win": {
		"lines": [
			"Сучка, твой раунд {0} : {1}",
			"Продолжаем!"
		],
		"choices": []  # Пустой массив - нет выборов!
	},
	"rps_lose": {
		"lines": [
			"Ха! Мой раунд {0} : {1}",
			"Давай еще раз!"
		],
		"choices": []  # Пустой массив - нет выборов!
	},
	"rps_draw": {
		"lines": [
			"Ничья! {0} : {1}",
			"Еще раз!"
		],
		"choices": []  # Пустой массив - нет выборов!
	},
"rps_victory": {
	"lines": [
		"[shake rate=20 level=10][color=#ffc485]АААААААААА[/color][/shake]",
		"Ты победила со счетом {0} : {1}!",
		"Ладно...",
		"Держи, это твоё."
	],
	"choices": []  # Нет выбора, просто заканчиваем
},
"rps_defeat": {
	"lines": [
		"[shake rate=10 level=10]ХА-ХА-ХА[/shake]",
		"Легкая со счётом {0} : {1}",
		"Бро, тебе нужно тренироваться!",
		"...",
		"Ладно, так уж и быть.",
		"Я разрешу тебе попытать удачу еще разок.",
	],
	"choices": []  # Нет выбора, автоматически перезапускаем
},
	"rps_restart": {
		"lines": [
			"Выбирай!"
		],
		"choices": [
			{
				"text": "Камень",
				"next": "rps_play"
			},
			{
				"text": "Ножницы",
				"next": "rps_play"
			},
			{
				"text": "Бумага",
				"next": "rps_play"
			}
		]
	}
}

# Signal with parameters
signal show_dialogue(dialogue_key: String)
signal hide_dialogue
signal give_reward

# Функция для проверки, все ли диалоги просмотрены
func check_all_dialogues_seen() -> bool:
	return seen_calendar and seen_flower and seen_bed and seen_wardrobe and seen_painting and seen_books

# Функция для сброса флагов
func reset_dialogue_flags() -> void:
	seen_calendar = false
	seen_flower = false
	seen_bed = false
	seen_wardrobe = false
	seen_painting = false
	seen_books = false
	seen_rps_intro = false

# Функция для отметки диалога как просмотренного
func mark_dialogue_seen(dialogue_key: String) -> void:
	match dialogue_key:
		"Календарь":
			seen_calendar = true
		"Цветок":
			seen_flower = true
		"Кровать":
			seen_bed = true
		"Шкаф":
			seen_wardrobe = true
		"Картина":
			seen_painting = true
		"Книги":
			seen_books = true
		"Хочу анекдот!":
			seen_books = true
		"rps_intro":
			seen_rps_intro = true

# Функция для сброса игры
func reset_rps_game() -> void:
	rps_player_score = 0
	rps_opponent_score = 0
	rps_game_active = true

# Функция для игры в камень-ножницы-бумага
func play_rps(player_choice: String) -> Dictionary:
	rps_player_choice = player_choice
	
	var choices = ["камень", "ножницы", "бумага"]
	rps_opponent_choice = choices[randi() % choices.size()]
	
	if rps_player_choice == rps_opponent_choice:
		rps_result = "ничья"
	elif (rps_player_choice == "камень" and rps_opponent_choice == "ножницы") or \
		 (rps_player_choice == "ножницы" and rps_opponent_choice == "бумага") or \
		 (rps_player_choice == "бумага" and rps_opponent_choice == "камень"):
		rps_result = "победа"
		rps_player_score += 1
	else:
		rps_result = "поражение"
		rps_opponent_score += 1
	
	return {
		"player": rps_player_choice,
		"opponent": rps_opponent_choice,
		"result": rps_result,
		"player_score": rps_player_score,
		"opponent_score": rps_opponent_score
	}

# Функция для проверки, закончена ли игра
func is_rps_game_finished() -> bool:
	return rps_player_score >= rps_max_score or rps_opponent_score >= rps_max_score

# Функция для проверки, проиграл ли игрок
func is_rps_player_defeated() -> bool:
	return rps_opponent_score >= rps_max_score

# Функция для проверки, выиграл ли игрок
func is_rps_player_victorious() -> bool:
	return rps_player_score >= rps_max_score

# Функция для получения ключа диалога результата
func get_rps_result_key() -> String:
	match rps_result:
		"победа":
			return "rps_win"
		"поражение":
			return "rps_lose"
		"ничья":
			return "rps_draw"
	return "rps_draw"
