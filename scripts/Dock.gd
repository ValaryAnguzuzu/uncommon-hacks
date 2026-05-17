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
signal home_requested
signal end_week_requested

const APP_RESUME := "resume"
const APP_WORK := "work"
const APP_PREP := "prep"
const APP_PROJECTS := "projects"
const APP_JOBS := "jobs"
const APP_INTERVIEW := "interview"

@onready var resume_button: Button = $DockRow/ResumeButton
@onready var home_button: Button = $DockRow/StartButton
@onready var work_button: Button = $DockRow/WorkButton
@onready var prep_button: Button = $DockRow/PrepButton
@onready var projects_button: Button = $DockRow/ProjectsButton
@onready var jobs_button: Button = $DockRow/JobsButton
@onready var interview_button: Button = $DockRow/InterviewButton
@onready var end_week_button: Button = $DockRow/EndWeekButton
@onready var interview_alert_badge: PanelContainer = $DockRow/InterviewButton/InterviewAlertBadge
@onready var interview_alert_count_label: Label = $DockRow/InterviewButton/InterviewAlertBadge/CountLabel

var interview_alert_tween: Tween


func _ready() -> void:
	home_button.pressed.connect(func(): home_requested.emit())
	resume_button.pressed.connect(func(): open_app_requested.emit(APP_RESUME))
	work_button.pressed.connect(func(): open_app_requested.emit(APP_WORK))
	prep_button.pressed.connect(func(): open_app_requested.emit(APP_PREP))
	projects_button.pressed.connect(func(): open_app_requested.emit(APP_PROJECTS))
	jobs_button.pressed.connect(func(): open_app_requested.emit(APP_JOBS))
	interview_button.pressed.connect(func(): open_app_requested.emit(APP_INTERVIEW))
	end_week_button.pressed.connect(func(): end_week_requested.emit())

	_apply_button_skins()
	_apply_responsive_layout()

	var refresh_callable := Callable(self, "refresh_alerts")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	refresh_alerts()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var compact: bool = size.x < 760.0
	var tiny: bool = size.x < 560.0
	var app_width: float = 74.0 if compact else 112.0
	var font_size: int = 12 if compact else 16

	home_button.custom_minimum_size = Vector2(62.0 if compact else 92.0, 52.0)
	resume_button.custom_minimum_size = Vector2(app_width, 52.0)
	prep_button.custom_minimum_size = Vector2(app_width, 52.0)
	work_button.custom_minimum_size = Vector2(app_width, 52.0)
	projects_button.custom_minimum_size = Vector2(app_width, 52.0)
	jobs_button.custom_minimum_size = Vector2(app_width, 52.0)
	interview_button.custom_minimum_size = Vector2(86.0 if compact else 130.0, 52.0)
	end_week_button.custom_minimum_size = Vector2(96.0 if compact else 146.0, 52.0)

	home_button.text = "Desk" if not tiny else "D"
	resume_button.text = "Resume" if not compact else "CV"
	prep_button.text = "Prep"
	work_button.text = "Work"
	projects_button.text = "Projects" if not compact else "Build"
	jobs_button.text = "Jobs"
	interview_button.text = "Interview" if not compact else "Talk"
	end_week_button.text = "End Week" if not compact else "End"

	for button in [home_button, resume_button, prep_button, work_button, projects_button, jobs_button, interview_button, end_week_button]:
		button.add_theme_font_size_override("font_size", font_size)


func _apply_button_skins() -> void:
	_style_button(home_button, Color(0.18, 0.44, 0.86), Color(0.51, 0.76, 1.0))
	_style_button(resume_button, Color(0.16, 0.48, 0.84), Color(0.45, 0.73, 1.0))
	_style_button(prep_button, Color(0.30, 0.55, 0.30), Color(0.62, 0.92, 0.55))
	_style_button(work_button, Color(0.70, 0.47, 0.13), Color(1.0, 0.77, 0.30))
	_style_button(projects_button, Color(0.42, 0.28, 0.70), Color(0.75, 0.56, 1.0))
	_style_button(jobs_button, Color(0.12, 0.52, 0.58), Color(0.50, 0.94, 1.0))
	_style_button(interview_button, Color(0.62, 0.25, 0.49), Color(1.0, 0.56, 0.85))
	_style_button(end_week_button, Color(0.80, 0.24, 0.14), Color(1.0, 0.64, 0.36))


func _style_button(button: Button, base_color: Color, accent_color: Color) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_stylebox_override("normal", _button_style(base_color, accent_color))
	button.add_theme_stylebox_override("hover", _button_style(base_color.lightened(0.14), accent_color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _button_style(base_color.darkened(0.18), accent_color.darkened(0.12)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _button_style(base_color: Color, accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = base_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = accent_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func refresh_alerts() -> void:
	# A dock alert should be obvious without blocking the player.
	var unlocked_count := PlayerState.new_interview_alerts.size()
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
