extends Control

# BootScreen is the first impression: title card, stakes, starting stats, then
# a fake OS boot into the playable desktop.

@onready var title_stack: VBoxContainer = $TitleStack
@onready var subtitle_label: Label = $TitleStack/SubtitleLabel
@onready var title_label: Label = $TitleStack/TitleLabel
@onready var stats_label: Label = $TitleStack/StatsLabel
@onready var start_button: Button = $TitleStack/StartButton
@onready var boot_stack: VBoxContainer = $BootStack
@onready var progress_bar: ProgressBar = $BootStack/ProgressBar
@onready var boot_status_label: Label = $BootStack/BootStatusLabel


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	boot_stack.visible = false
	title_stack.modulate = Color(1, 1, 1, 0)
	var intro_position: Vector2 = title_stack.position
	intro_position.y += 18.0
	title_stack.position = intro_position
	_apply_responsive_layout()

	stats_label.text = "%s weeks. $%s cash. $%s debt.\nGet an offer before graduation pressure wins." % [
		PlayerState.max_weeks,
		PlayerState.checking_balance,
		PlayerState.debt
	]

	var intro_tween: Tween = create_tween()
	intro_tween.tween_property(title_stack, "modulate", Color(1, 1, 1, 1), 0.55)
	intro_tween.parallel().tween_property(title_stack, "position:y", intro_position.y - 18.0, 0.55)
	intro_tween.tween_property(title_label, "scale", Vector2(1.02, 1.02), 0.35)
	intro_tween.tween_property(title_label, "scale", Vector2.ONE, 0.25)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var viewport_width: float = maxf(size.x, 640.0)
	var title_size: int = clampi(int(viewport_width * 0.085), 58, 112)
	var body_size: int = clampi(int(viewport_width * 0.015), 14, 18)
	var button_width: float = clampf(viewport_width * 0.34, 300.0, 430.0)

	if title_label.label_settings != null:
		title_label.label_settings.font_size = title_size

	subtitle_label.add_theme_font_size_override("font_size", body_size)
	stats_label.add_theme_font_size_override("font_size", body_size)
	start_button.custom_minimum_size = Vector2(button_width, 70)


func _on_start_pressed() -> void:
	start_button.disabled = true
	start_button.text = "BOOTING..."
	boot_stack.visible = true
	progress_bar.value = 0

	var manager: Node = get_node_or_null("/root/GameManager")
	if manager != null:
		manager.call("start_new_run")

	var boot_tween: Tween = create_tween()
	boot_tween.tween_property(title_stack, "modulate", Color(1, 1, 1, 0.18), 0.25)
	boot_tween.parallel().tween_property(progress_bar, "value", 100.0, 1.25)
	boot_tween.tween_callback(func(): boot_status_label.text = "opening desktop...")
	boot_tween.tween_interval(0.32)
	boot_tween.tween_callback(func(): get_tree().change_scene_to_file("res://Main.tscn"))
