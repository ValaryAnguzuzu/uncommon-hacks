extends PanelContainer

# TopMenuBar is a read-only view of PlayerState.
#
# General behavior:
# - On ready, it fills every label with the current PlayerState values.
# - It listens for PlayerState.state_changed so the UI refreshes after actions.
# - It should not own game rules. It only displays state and forwards button
#   clicks to managers or PlayerState helpers.
# - Keep this bar focused on urgent survival stats. Resume keywords belong in
#   ResumeWindow, where the player can inspect their full build.
# - The dock owns End Week, and Desktop owns the prominent week timer.

@onready var objective_label: Label = $HudRow/IdentityStack/ObjectiveLabel
@onready var identity_stack: VBoxContainer = $HudRow/IdentityStack
@onready var stats_row: HBoxContainer = $HudRow/StatsRow
@onready var week_label: Label = $HudRow/StatsRow/WeekCard/WeekLabel
@onready var money_label: Label = $HudRow/StatsRow/MoneyCard/MoneyLabel
@onready var debt_label: Label = $HudRow/StatsRow/DebtCard/DebtLabel
@onready var burnout_label: Label = $HudRow/StatsRow/BurnoutCard/BurnoutLabel
@onready var confidence_label: Label = $HudRow/StatsRow/ConfidenceCard/ConfidenceLabel
@onready var interview_skill_label: Label = $HudRow/StatsRow/InterviewCard/InterviewSkillLabel
@onready var score_label: Label = $HudRow/StatsRow/ScoreCard/ScoreRow/ScoreLabel


func _ready() -> void:
	# Connect once so every PlayerState helper automatically updates the bar.
	var refresh_callable := Callable(self, "refresh")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	_apply_responsive_layout()
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()


func refresh() -> void:
	# Pull values from PlayerState each time instead of storing duplicate copies.
	week_label.text = "Week %s/%s" % [PlayerState.week_num, PlayerState.max_weeks]
	money_label.text = "$%s" % PlayerState.checking_balance
	debt_label.text = "Debt $%s" % PlayerState.debt
	burnout_label.text = "Burnout %s%%" % PlayerState.burnout
	confidence_label.text = "Confidence %s%%" % PlayerState.confidence
	interview_skill_label.text = "Interview %s%%" % PlayerState.interview_skill
	score_label.text = "Coins %s" % PlayerState.score
	objective_label.text = ""

	money_label.add_theme_color_override("font_color", _money_color())
	debt_label.add_theme_color_override("font_color", _debt_color())
	burnout_label.add_theme_color_override("font_color", _burnout_color())
	confidence_label.add_theme_color_override("font_color", _confidence_color())
	interview_skill_label.add_theme_color_override("font_color", Color(0.70, 0.88, 1.0))
	score_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.26))
	week_label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.95))


func _apply_responsive_layout() -> void:
	var compact: bool = size.x < 1080.0
	var font_size: int = 11 if compact else 12

	objective_label.visible = false
	identity_stack.custom_minimum_size = Vector2(86, 0) if compact else Vector2(130, 0)
	stats_row.alignment = BoxContainer.ALIGNMENT_END
	stats_row.add_theme_constant_override("separation", 8 if compact else 14)

	for label in [
		week_label,
		money_label,
		debt_label,
		burnout_label,
		confidence_label,
		interview_skill_label,
		score_label,
	]:
		label.add_theme_font_size_override("font_size", font_size)


func _money_color() -> Color:
	if PlayerState.checking_balance < 0:
		return Color(0.95, 0.38, 0.34)

	if PlayerState.checking_balance < 150:
		return Color(0.96, 0.72, 0.30)

	return Color(0.88, 0.92, 0.95)


func _debt_color() -> Color:
	if PlayerState.debt <= 0:
		return Color(0.45, 0.92, 0.62)

	if PlayerState.debt > 1400:
		return Color(0.96, 0.72, 0.30)

	return Color(0.88, 0.92, 0.95)


func _burnout_color() -> Color:
	if PlayerState.burnout >= 80:
		return Color(0.95, 0.38, 0.34)

	if PlayerState.burnout >= 55:
		return Color(0.96, 0.72, 0.30)

	return Color(0.88, 0.92, 0.95)


func _confidence_color() -> Color:
	if PlayerState.confidence <= 25:
		return Color(0.95, 0.38, 0.34)

	if PlayerState.confidence <= 45:
		return Color(0.96, 0.72, 0.30)

	return Color(0.88, 0.92, 0.95)
