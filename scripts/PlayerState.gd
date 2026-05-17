# PlayerState is the source of truth for the current run.
#
# It should hold the player's changing game data:
# - current week
# - checking/money
# - Discover debt
# - burnout
# - confidence
# - interview skill
# - score
# - resume keywords
# - completed projects
# - applications sent
# - active interviews
#
# Other managers should read from and update PlayerState instead of keeping separate copies of these values.
#
# General behavior:
# - This script stores the current run's state; it does not decide every rule.
# - Managers should call helper functions here instead of editing arrays and stats directly when possible.
# - Helper functions emit state_changed so UI scenes can refresh after changes.
# - GameManager should still decide high-level outcomes like win/loss and week-end consequences.
# - Project, job, and interview-specific rules can move into their own managers while still storing final results here.
extends Node

# 

# UI and managers can listen to this instead of polling every frame.
signal state_changed
signal interview_unlocked(job_id: String)

# Money and debt
@export var checking_balance: int = 500
@export var debt: int = 1200
@export var debt_active: bool = false
@export var debt_minimum_payment: int = 50
@export var used_lifeline: bool = false

# Run progress controls the graduation timer and future idle pressure.
@export var week_num: int = 1
@export var max_weeks: int = 15
@export var seconds_per_week: float = 157.5
@export var idle_seconds_left: float = 75.0

# Mental state; between 0 and 100.
@export_range(0, 100) var burnout: int = 10
@export_range(0, 100) var confidence: int = 50

# Career progress affects applications, interviews, and scoring.
@export_range(0, 100) var interview_skill: int = 20
@export var score: int = 0
@export var resume_score: int = 0
@export var applications_sent: int = 0

# Action points gate how many work actions the player can take per week.
@export var action_points_per_week: int = 2
@export var action_points_remaining: int = 2

# Resume data is the player's "build" for job matching.
var resume_keywords: Array[String] = ["Git"]
var completed_projects: Array[String] = []
var active_interviews: Array[String] = []

# Project progress is keyed by project id, for example "portfolio_site".
var project_progress: Dictionary = {}
var active_project_id: String = ""

# Job ids move through these lists as the application flow advances.
var applied_jobs: Array[String] = []
var viewed_jobs: Array[String] = []
var unlocked_interviews: Array[String] = []
var new_interview_alerts: Array[String] = []
var active_interview_job_id: String = ""

# Interview state tracks one active interview session at a time.
var current_interview_question_index: int = 0
var current_interview_score: int = 0

# Ending state lets GameManager and UI know when the run is over.
var has_offer: bool = false
var offer_job_id: String = ""
var has_lost: bool = false
var lose_reason: String = ""


func reset_run() -> void:
	# Keep reset values in one place so restarting a run is predictable.
	checking_balance = 500
	debt = 1200
	debt_active = false
	debt_minimum_payment = 50
	used_lifeline = false
	week_num = 1
	idle_seconds_left = seconds_per_week
	burnout = 10
	confidence = 50
	interview_skill = 20
	score = 0
	resume_score = 0
	applications_sent = 0
	action_points_remaining = action_points_per_week
	resume_keywords = ["Git"]
	completed_projects = []
	active_interviews = []
	project_progress = {}
	active_project_id = ""
	applied_jobs = []
	viewed_jobs = []
	unlocked_interviews = []
	new_interview_alerts = []
	active_interview_job_id = ""
	current_interview_question_index = 0
	current_interview_score = 0
	has_offer = false
	offer_job_id = ""
	has_lost = false
	lose_reason = ""
	state_changed.emit()


func add_money(amount: int) -> void:
	# so UI refreshes happen consistently.
	checking_balance += amount
	state_changed.emit()


func spend_money(amount: int) -> void:
	# This can make checking_balance negative; GameManager should decide loss.
	checking_balance -= amount
	state_changed.emit()


func reduce_debt(amount: int) -> void:
	debt = maxi(debt - amount, 0)
	state_changed.emit()


func add_burnout(amount: int) -> void:
	# Clamp prevents invalid values like -10 or 140.
	burnout = clampi(burnout + amount, 0, 100)
	state_changed.emit()


func add_confidence(amount: int) -> void:
	# amount can be positive or negative.
	confidence = clampi(confidence + amount, 0, 100)
	state_changed.emit()


func add_interview_skill(amount: int) -> void:
	# Interview prep should improve this over time, but never past 100.
	interview_skill = clampi(interview_skill + amount, 0, 100)
	state_changed.emit()


func add_score(amount: int) -> void:
	score += amount
	state_changed.emit()


func add_resume_score(amount: int) -> void:
	resume_score += amount
	state_changed.emit()


func add_application(job_id: String = "") -> void:
	# job_id is optional so generic application actions can still count.
	applications_sent += 1

	if job_id != "" and job_id not in applied_jobs:
		applied_jobs.append(job_id)

	state_changed.emit()

# helper functions for other scripts to modify unexported stuff
func add_keyword(keyword: String) -> void:
	# Prevent duplicate resume tags.
	if keyword not in resume_keywords:
		resume_keywords.append(keyword)
		state_changed.emit()


func complete_project(project_id: String) -> void:
	# Completed projects should only be recorded once.
	if project_id not in completed_projects:
		completed_projects.append(project_id)
		state_changed.emit()


func add_active_interview(job_id: String) -> void:
	# Active interviews are tracked by job id.
	if job_id not in active_interviews:
		active_interviews.append(job_id)
		state_changed.emit()


func set_project_progress(project_id: String, progress: int) -> void:
	# Managers can decide max progress; PlayerState just stores the value.
	project_progress[project_id] = progress
	state_changed.emit()


func mark_job_viewed(job_id: String) -> void:
	if job_id not in viewed_jobs:
		viewed_jobs.append(job_id)
		state_changed.emit()


func unlock_interview(job_id: String) -> void:
	# Unlocking an interview also makes it available in active_interviews.
	var is_new_unlock := job_id not in unlocked_interviews

	if is_new_unlock:
		unlocked_interviews.append(job_id)

	if job_id not in new_interview_alerts:
		new_interview_alerts.append(job_id)

	add_active_interview(job_id)
	if is_new_unlock:
		interview_unlocked.emit(job_id)
	state_changed.emit()


func acknowledge_interview_alerts() -> void:
	# Opening the Interview app clears the dock/toast attention state without
	# removing the actual unlocked interviews.
	if new_interview_alerts.is_empty():
		return

	new_interview_alerts = []
	state_changed.emit()


func start_interview(job_id: String) -> void:
	# Starting a new interview resets question position and score.
	active_interview_job_id = job_id
	current_interview_question_index = 0
	current_interview_score = 0
	state_changed.emit()


func finish_interview(job_id: String) -> void:
	if job_id in active_interviews:
		active_interviews.erase(job_id)

	if job_id in unlocked_interviews:
		unlocked_interviews.erase(job_id)

	if job_id in new_interview_alerts:
		new_interview_alerts.erase(job_id)

	if active_interview_job_id == job_id:
		active_interview_job_id = ""
		current_interview_question_index = 0
		current_interview_score = 0

	state_changed.emit()


func add_interview_score(amount: int) -> void:
	current_interview_score += amount
	state_changed.emit()


func advance_interview_question() -> void:
	current_interview_question_index += 1
	state_changed.emit()


func set_offer(job_id: String) -> void:
	# The win screen can use offer_job_id to show where the offer came from.
	has_offer = true
	offer_job_id = job_id
	state_changed.emit()


func set_loss(reason: String) -> void:
	# Store the reason so LoseScreen can show grounded feedback.
	has_lost = true
	lose_reason = reason
	state_changed.emit()


func spend_action_point() -> void:
	action_points_remaining = maxi(action_points_remaining - 1, 0)
	state_changed.emit()


func advance_week() -> void:
	# Reset idle timer and action points at the start of each new week.
	week_num += 1
	idle_seconds_left = seconds_per_week
	action_points_remaining = action_points_per_week
	state_changed.emit()
