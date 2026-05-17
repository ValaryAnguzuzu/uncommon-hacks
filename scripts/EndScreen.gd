extends Control

# Shared ending screen script for win and loss.
# It reads PlayerState at the end of the run so the result feels connected to
# the player's actual choices instead of being a static placeholder.

@export var won: bool = false

@onready var title_label: Label = $CenterStack/TitleLabel
@onready var body_label: Label = $CenterStack/BodyLabel
@onready var stats_label: Label = $CenterStack/StatsPanel/StatsMargin/StatsLabel
@onready var restart_button: Button = $RestartButton


func _ready() -> void:
	_apply_theme()
	title_label.text = _title_text()
	body_label.text = _body_text()
	stats_label.text = _stats_text()
	restart_button.pressed.connect(_restart)


func _apply_theme() -> void:
	var accent: Color = Color(0.22, 1.0, 0.55) if won else Color(1.0, 0.28, 0.28)
	title_label.add_theme_color_override("font_color", accent)
	restart_button.add_theme_color_override("font_color", accent)
	restart_button.add_theme_color_override("font_hover_color", accent.lightened(0.25))

	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color(0, 0, 0, 0)
	button_style.border_width_left = 1
	button_style.border_width_top = 1
	button_style.border_width_right = 1
	button_style.border_width_bottom = 1
	button_style.border_color = accent
	button_style.corner_radius_top_left = 6
	button_style.corner_radius_top_right = 6
	button_style.corner_radius_bottom_right = 6
	button_style.corner_radius_bottom_left = 6
	button_style.content_margin_left = 34
	button_style.content_margin_top = 14
	button_style.content_margin_right = 34
	button_style.content_margin_bottom = 14
	restart_button.add_theme_stylebox_override("normal", button_style)
	restart_button.add_theme_stylebox_override("hover", button_style)
	restart_button.add_theme_stylebox_override("pressed", button_style)
	restart_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _title_text() -> String:
	if won:
		return "YOU GOT HIRED."

	if PlayerState.lose_reason.to_lower().contains("checking"):
		return "CRIPPLING DEBT."

	if PlayerState.lose_reason.to_lower().contains("graduation"):
		return "GRADUATED BROKE."

	return "YOU SANK."


func _body_text() -> String:
	if won:
		return "The offer letter finally arrived. The laptop hum sounds different now. You stayed afloat long enough to turn proof into a way out."

	if PlayerState.lose_reason.to_lower().contains("checking"):
		return "The card declined. Rent did not wait. The job search collapsed before the offer arrived."

	if PlayerState.lose_reason.to_lower().contains("graduation"):
		return "Graduation arrived before the offer did. The inbox stayed quiet."

	if PlayerState.lose_reason != "":
		return PlayerState.lose_reason

	return "The pressure won this run."


func _stats_text() -> String:
	return "SCORE: %s\nWEEK: %s / %s\nAPPLICATIONS: %s\nPROJECTS SHIPPED: %s\nRESUME KEYWORDS: %s\nBALANCE: $%s\nDEBT LEFT: $%s\nBURNOUT: %s%%" % [
		PlayerState.score,
		PlayerState.week_num,
		PlayerState.max_weeks,
		PlayerState.applications_sent,
		PlayerState.completed_projects.size(),
		PlayerState.resume_keywords.size(),
		PlayerState.checking_balance,
		PlayerState.debt,
		PlayerState.burnout
	]


func _restart() -> void:
	PlayerState.reset_run()
	get_tree().change_scene_to_file("res://BootScreen.tscn")
