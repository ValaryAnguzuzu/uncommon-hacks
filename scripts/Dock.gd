extends PanelContainer

# Dock is the fake desktop app launcher.
#
# General behavior:
# - It does not create windows by itself.
# - It emits open_app_requested with an app id.
# - Desktop listens to that signal and decides where/how to open the window.
# This keeps dock UI separate from desktop window management.
# - It also listens to PlayerState so important apps can visually ask for
#   attention. Right now Interview pulses when interviews are unlocked.

signal open_app_requested(app_id: String)

const APP_RESUME := "resume"
const APP_WORK := "work"
const APP_PREP := "prep"
const APP_PROJECTS := "projects"
const APP_JOBS := "jobs"
const APP_INTERVIEW := "interview"

@onready var resume_button: Button = $DockRow/ResumeButton
@onready var work_button: Button = $DockRow/WorkButton
@onready var prep_button: Button = $DockRow/PrepButton
@onready var projects_button: Button = $DockRow/ProjectsButton
@onready var jobs_button: Button = $DockRow/JobsButton
@onready var interview_button: Button = $DockRow/InterviewButton
@onready var interview_alert_badge: PanelContainer = $DockRow/InterviewButton/InterviewAlertBadge
@onready var interview_alert_count_label: Label = $DockRow/InterviewButton/InterviewAlertBadge/CountLabel

var interview_alert_tween: Tween


func _ready() -> void:
	resume_button.pressed.connect(func(): open_app_requested.emit(APP_RESUME))
	work_button.pressed.connect(func(): open_app_requested.emit(APP_WORK))
	prep_button.pressed.connect(func(): open_app_requested.emit(APP_PREP))
	projects_button.pressed.connect(func(): open_app_requested.emit(APP_PROJECTS))
	jobs_button.pressed.connect(func(): open_app_requested.emit(APP_JOBS))
	interview_button.pressed.connect(func(): open_app_requested.emit(APP_INTERVIEW))

	var refresh_callable := Callable(self, "refresh_alerts")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	refresh_alerts()


func refresh_alerts() -> void:
	# A dock alert should be obvious without blocking the player.
	var unlocked_count := PlayerState.unlocked_interviews.size()
	var should_alert := unlocked_count > 0

	interview_alert_badge.visible = should_alert
	interview_alert_count_label.text = str(unlocked_count) if unlocked_count > 1 else "!"

	if should_alert:
		_start_interview_alert()
	else:
		_stop_interview_alert()


func _start_interview_alert() -> void:
	if interview_alert_tween != null and interview_alert_tween.is_running():
		return

	interview_alert_tween = create_tween()
	interview_alert_tween.set_loops()
	interview_alert_tween.tween_property(interview_button, "modulate", Color(0.72, 1.0, 0.82, 1.0), 0.45)
	interview_alert_tween.tween_property(interview_button, "modulate", Color(1, 1, 1, 1), 0.45)


func _stop_interview_alert() -> void:
	if interview_alert_tween != null:
		interview_alert_tween.kill()
		interview_alert_tween = null

	interview_button.modulate = Color(1, 1, 1, 1)
