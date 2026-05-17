extends PanelContainer

# Dock is the fake desktop app launcher.
#
# General behavior:
# - It does not create windows by itself.
# - It emits open_app_requested with an app id.
# - Desktop listens to that signal and decides where/how to open the window.
# This keeps dock UI separate from desktop window management.

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


func _ready() -> void:
	resume_button.pressed.connect(func(): open_app_requested.emit(APP_RESUME))
	work_button.pressed.connect(func(): open_app_requested.emit(APP_WORK))
	prep_button.pressed.connect(func(): open_app_requested.emit(APP_PREP))
	projects_button.pressed.connect(func(): open_app_requested.emit(APP_PROJECTS))
	jobs_button.pressed.connect(func(): open_app_requested.emit(APP_JOBS))
	interview_button.pressed.connect(func(): open_app_requested.emit(APP_INTERVIEW))
