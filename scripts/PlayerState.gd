extends Node

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
# Other managers should read from and update PlayerState instead of keeping
# separate copies of these values.
extends Node

# Money
@export var checking_balance: int = 500
@export var debt: int = 1200

# Run Progress
@export var week_num: int = 1
@export var max_weeks: int = 15

# Mental State
@export_range(0, 100) var burnout: int = 10
@export_range(0, 100) var confidence: int = 50

# Career progress
@export_range(0, 100) var interview_skill: int = 20
@export var score: int = 0
@export var applications_sent: int = 0

# Info about the player that is updated throughout the game
var resume_keywords: Array[String] = ["Git"]
var completed_projects: Array[String] = []
var active_interviews: Array[String] = []

# helper functions for other scripts to modify unexported stuff
func add_keyword(keyword: String) -> void:
	if keyword not in resume_keywords:
			resume_keywords.append(keyword)


func complete_project(project_id: String) -> void:
	if project_id not in completed_projects:
			completed_projects.append(project_id)


func add_active_interview(job_id: String) -> void:
	if job_id not in active_interviews:
			active_interviews.append(job_id)
