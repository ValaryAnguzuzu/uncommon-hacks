extends PanelContainer

@onready var close_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/CloseDot
@onready var close_button: Button = $OuterMargin/WindowStack/TitleBar/CloseButton
@onready var stats_label: Label = $OuterMargin/WindowStack/Body/StatsLabel


func _ready() -> void:
	close_dot.pressed.connect(hide)
	close_button.pressed.connect(hide)

	var refresh_callable := Callable(self, "refresh")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	refresh()


func refresh() -> void:
	stats_label.text = "TODAY'S PRESSURE\n%s\n\nNEXT BEST MOVE\n%s\n\nWEEK: %s / %s\nTIME LEFT: %s\nACTIONS LEFT: %s\nCASH: $%s\nDEBT: $%s\nBURNOUT: %s%%\nCONFIDENCE: %s%%\nINTERVIEW SKILL: %s%%\nCOINS: %s" % [
		_crisis_text(),
		_objective_text(),
		PlayerState.week_num,
		PlayerState.max_weeks,
		_format_timer(PlayerState.idle_seconds_left),
		PlayerState.action_points_remaining,
		PlayerState.checking_balance,
		PlayerState.debt,
		PlayerState.burnout,
		PlayerState.confidence,
		PlayerState.interview_skill,
		PlayerState.score,
	]


func _crisis_text() -> String:
	if PlayerState.checking_balance < 0:
		return "Overdraft. Earn cash before the search collapses."

	if PlayerState.burnout >= 80:
		return "Burnout spike. Recover before interviews punish you."

	if PlayerState.unlocked_interviews.size() > 0:
		return "Interview ready. Prep or take the screen."

	if PlayerState.week_num >= PlayerState.max_weeks - 3:
		return "Final stretch. Apply to anything you can match."

	return "Rent, debt, and graduation are moving whether you act or not."


func _objective_text() -> String:
	if PlayerState.unlocked_interviews.size() > 0:
		return "Open Interview when ready. Prep first if confidence is low."

	if PlayerState.resume_keywords.size() < 4:
		return "Ship a project to unlock recruiter keywords."

	if PlayerState.applications_sent == 0:
		return "Open Jobs and target high-match roles."

	if PlayerState.action_points_remaining <= 0:
		return "No actions left. End the week."

	return "Build leverage: earn, ship, apply, prep."


func _format_timer(seconds_left: float) -> String:
	var total_seconds: int = ceili(seconds_left)
	var minutes: int = floori(float(total_seconds) / 60.0)
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
