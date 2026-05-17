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
# - End Week calls PlayerState.advance_week() for now so we can test the state
#   refresh loop before GameManager owns week-end rules.

@onready var week_label: Label = $StatsRow/WeekLabel
@onready var money_label: Label = $StatsRow/MoneyLabel
@onready var debt_label: Label = $StatsRow/DebtLabel
@onready var burnout_label: Label = $StatsRow/BurnoutLabel
@onready var confidence_label: Label = $StatsRow/ConfidenceLabel
@onready var interview_skill_label: Label = $StatsRow/InterviewSkillLabel
@onready var score_label: Label = $StatsRow/ScoreLabel
@onready var end_week_button: Button = $StatsRow/EndWeekButton


func _ready() -> void:
	# Connect once so every PlayerState helper automatically updates the bar.
	var refresh_callable := Callable(self, "refresh")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	end_week_button.pressed.connect(_on_end_week_button_pressed)
	refresh()


func refresh() -> void:
	# Pull values from PlayerState each time instead of storing duplicate copies.
	week_label.text = "Week %s/%s" % [PlayerState.week_num, PlayerState.max_weeks]
	money_label.text = "$%s" % PlayerState.checking_balance
	debt_label.text = "Debt $%s" % PlayerState.debt
	burnout_label.text = "Burnout %s%%" % PlayerState.burnout
	confidence_label.text = "Confidence %s%%" % PlayerState.confidence
	interview_skill_label.text = "Interview %s%%" % PlayerState.interview_skill
	score_label.text = "Score %s" % PlayerState.score


func _on_end_week_button_pressed() -> void:
	# Temporary direct call. Later this should become GameManager.end_week().
	PlayerState.advance_week()
