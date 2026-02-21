extends Control

@onready var calendar_button: Button = %calendar_button
@onready var painting_button: Button = %painting_button
@onready var bed_button: Button = %bed_button
@onready var flower_button: Button = %flower_button
@onready var wardrobe_button: Button = %wardrobe_button
@onready var books_button: Button = %books_button

@onready var calendar: AnimatedSprite2D = %Calendar
@onready var painting: AnimatedSprite2D = %Painting
@onready var bed: AnimatedSprite2D = %Bed
@onready var flower: AnimatedSprite2D = %Flower
@onready var wardrobe: AnimatedSprite2D = %Wardrobe
@onready var books: AnimatedSprite2D = %Books
@onready var room: AnimatedSprite2D = %Room
@onready var camera_2d: Camera2D = %Camera2D

@onready var object_sfx: AudioStreamPlayer = %object_sfx


# Dictionary to link buttons to their corresponding sprites and camera offsets
var button_to_sprite: Dictionary = {}
var button_to_camera_offset: Dictionary = {}

# Array to easily manage all object sprites
var all_sprites: Array = []
var original_camera_zoom: Vector2
var original_camera_offset: Vector2

func _ready():
	# Fill the dictionary linking buttons to sprites
	button_to_sprite = {
		calendar_button: calendar,
		painting_button: painting,
		bed_button: bed,
		flower_button: flower,
		wardrobe_button: wardrobe,
		books_button: books
	}
	
	# Fill the dictionary linking buttons to camera offsets
	# You can customize these offsets for each object
	button_to_camera_offset = {
		calendar_button: Vector2(-50, 0),
		painting_button: Vector2(-220, 120),
		bed_button: Vector2(-220, 350),
		flower_button: Vector2(0, 0),
		wardrobe_button: Vector2(320, 300),
		books_button: Vector2(-220, 120)
	}
	
	# Fill the array with all sprites (including room)
	all_sprites = [
		calendar,
		painting,
		bed,
		flower,
		wardrobe,
		books,
		room
	]
	
	# Save original camera values
	original_camera_zoom = camera_2d.zoom
	original_camera_offset = camera_2d.offset
	
	reset_objects_opacity()
	reset_camera()
	Global.hide_dialogue.connect(reset_objects_opacity)
	Global.hide_dialogue.connect(reset_camera)
	Global.hide_dialogue.connect(_on_dialogue_ended)

func _on_dialogue_ended() -> void:
	# Проверяем, все ли диалоги просмотрены и не было ли уже игры
	if Global.check_all_dialogues_seen() and not Global.seen_rps_intro:
		# Небольшая задержка, чтобы предыдущий диалог полностью закрылся
		await get_tree().create_timer(0.1).timeout
		# Запускаем финальный диалог с игрой
		Global.mark_dialogue_seen("rps_intro")
		Global.show_dialogue.emit("rps_intro")

func reset_objects_opacity() -> void:
	# Reset all sprites to full opacity
	for sprite in all_sprites:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

func reset_camera() -> void:
	# Reset camera to original values
	var tween = create_tween().set_parallel().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera_2d, "zoom", original_camera_zoom, 0.3)
	tween.tween_property(camera_2d, "offset", original_camera_offset, 0.3)

func focus_object(clicked_button: Button) -> void:
	object_sfx.pitch_scale = randf_range(1,1.1)
	object_sfx.play()
	# Get the sprite corresponding to the clicked button
	var clicked_sprite = button_to_sprite.get(clicked_button)
	
	# Get the camera offset for this object
	var camera_offset = button_to_camera_offset.get(clicked_button, Vector2(0, 0))
	
	# Fade out all sprites EXCEPT the clicked one
	for sprite in all_sprites:
		if sprite != clicked_sprite:
			var tween = create_tween()
			# Room fades to 0.6, other objects to 0.2
			if sprite == room:
				tween.tween_property(sprite, "modulate:a", 0.6, 0.3)
			else:
				tween.tween_property(sprite, "modulate:a", 0.2, 0.3)
	
	# Make sure clicked sprite stays at full opacity
	if clicked_sprite:
		clicked_sprite.modulate.a = 1.0
	
	# Animate camera
	var camera_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	camera_tween.tween_property(camera_2d, "zoom", Vector2(1.4, 1.4), 0.3)
	camera_tween.tween_property(camera_2d, "offset", camera_offset, 0.3)
	
	# Optional: Add a slight scale animation to clicked button
	var scale_tween = create_tween().set_parallel()
	scale_tween.tween_property(clicked_button, "scale", Vector2(1.1, 1.1), 0.15)
	scale_tween.tween_property(clicked_button, "scale", Vector2(1.0, 1.0), 0.15).set_delay(0.15)

func _on_calendar_button_pressed() -> void:
	focus_object(calendar_button)
	Global.show_dialogue.emit("Календарь")
	Global.mark_dialogue_seen("Календарь")

func _on_painting_button_pressed() -> void:
	focus_object(painting_button)
	Global.show_dialogue.emit("Картина")
	Global.mark_dialogue_seen("Картина")

func _on_bed_button_pressed() -> void:
	focus_object(bed_button)
	Global.show_dialogue.emit("Кровать")
	Global.mark_dialogue_seen("Кровать")

func _on_flower_button_pressed() -> void:
	focus_object(flower_button)
	Global.show_dialogue.emit("Цветок")
	Global.mark_dialogue_seen("Цветок")

func _on_wardrobe_button_pressed() -> void:
	focus_object(wardrobe_button)
	Global.show_dialogue.emit("Шкаф")
	Global.mark_dialogue_seen("Шкаф")

func _on_books_button_pressed() -> void:
	focus_object(books_button)
	Global.show_dialogue.emit("Книги")
	# Не отмечаем сразу, так как там есть выбор
