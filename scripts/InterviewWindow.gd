extends PanelContainer

# InterviewWindow shows the interviews the player has earned.
#
# General behavior:
# - Reads job metadata from data/jobs.json so interview cards use real company/title data.
# - Displays only jobs listed in PlayerState.unlocked_interviews.
# - Starting an interview sets PlayerState.active_interview_job_id for the future question flow.
# - Opening this app already clears the dock alert through Desktop.gd; this window focuses on the queue.

const JOBS_PATH := "res://data/jobs.json"
const QUESTIONS := [
	{
		"prompt": "The recruiter asks: 'Walk me through a project you shipped.'",
		"answers": [
			{"text": "Name the problem, your specific choices, and what improved.", "score": 7, "feedback": "Strong. Specific evidence beats buzzwords."},
			{"text": "List every framework you touched as fast as possible.", "score": 3, "feedback": "Some signal, but it sounds like a stack dump."},
			{"text": "Say it was a school project and move on.", "score": 0, "feedback": "Too thin. They needed proof of ownership."}
		]
	},
	{
		"prompt": "They ask: 'What would you do if you got stuck for half a day?'",
		"answers": [
			{"text": "Debug, document attempts, ask a targeted question, then follow up.", "score": 7, "feedback": "Excellent. This sounds employable."},
			{"text": "Keep grinding alone until it works.", "score": 2, "feedback": "Persistence is good, silence is expensive."},
			{"text": "Switch tasks and hope it clears up.", "score": 1, "feedback": "Avoidance reads risky in an internship."}
		]
	},
	{
		"prompt": "Final question: 'Why this role?'",
		"answers": [
			{"text": "Connect their product, your projects, and the skills you want to grow.", "score": 7, "feedback": "Great close. You made the match feel intentional."},
			{"text": "Say you need experience and are open to anything.", "score": 2, "feedback": "Honest, but it undersells you."},
			{"text": "Mention the job market is rough.", "score": 0, "feedback": "Real, but not a closing argument."}
		]
	}
]

@onready var close_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowDots/CloseDot
@onready var zoom_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowDots/ZoomDot
@onready var close_button: Button = $OuterMargin/WindowStack/TitleBar/CloseButton
@onready var empty_state_label: Label = $OuterMargin/WindowStack/BodyPanel/BodyMargin/BodyStack/EmptyStateLabel
@onready var interview_list: VBoxContainer = $OuterMargin/WindowStack/BodyPanel/BodyMargin/BodyStack/ScrollContainer/InterviewList
@onready var focus_label: Label = $OuterMargin/WindowStack/BodyPanel/BodyMargin/BodyStack/FocusLabel

var jobs_by_id: Dictionary = {}
var _is_expanded: bool = false
var _saved_offsets: Vector4 = Vector4.ZERO


func _ready() -> void:
	close_dot.pressed.connect(_on_close_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	zoom_dot.pressed.connect(func(): _toggle_expand())

	var refresh_callable := Callable(self, "refresh")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	_load_jobs()
	refresh()


func refresh() -> void:
	_clear_container(interview_list)

	var unlocked_ids: Array[String] = PlayerState.unlocked_interviews
	empty_state_label.visible = unlocked_ids.is_empty()
	focus_label.text = _focus_text()

	if PlayerState.active_interview_job_id != "":
		var active_job: Dictionary = jobs_by_id.get(PlayerState.active_interview_job_id, {})
		interview_list.add_child(_make_question_card(PlayerState.active_interview_job_id, active_job))

	for job_id in unlocked_ids:
		if str(job_id) == PlayerState.active_interview_job_id:
			continue

		var job: Dictionary = jobs_by_id.get(job_id, {})
		interview_list.add_child(_make_interview_card(str(job_id), job))


func _load_jobs() -> void:
	var file := FileAccess.open(JOBS_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not load interview job data: %s" % JOBS_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Interview job data must be a JSON array.")
		return

	for job in parsed:
		if typeof(job) != TYPE_DICTIONARY:
			continue

		var job_id := str(job.get("id", ""))
		if job_id != "":
			jobs_by_id[job_id] = job


func _make_interview_card(job_id: String, job: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_style(job_id == PlayerState.active_interview_job_id))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)

	var top_row := HBoxContainer.new()
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_label := Label.new()
	title_label.text = str(job.get("title", "Interview"))
	title_label.add_theme_color_override("font_color", Color(0.05, 0.07, 0.10))

	var company_label := Label.new()
	company_label.text = str(job.get("company", "Unknown Company"))
	company_label.add_theme_color_override("font_color", Color(0.28, 0.34, 0.42))

	var status_label := Label.new()
	status_label.text = "ACTIVE" if job_id == PlayerState.active_interview_job_id else "READY"
	status_label.add_theme_color_override("font_color", Color(0.09, 0.46, 0.28))

	title_stack.add_child(title_label)
	title_stack.add_child(company_label)
	top_row.add_child(title_stack)
	top_row.add_child(status_label)

	var detail_label := Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.text = _interview_brief(job)
	detail_label.add_theme_color_override("font_color", Color(0.22, 0.26, 0.32))

	var action_row := HBoxContainer.new()
	var prep_label := Label.new()
	prep_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prep_label.text = "Confidence %s / Skill %s" % [PlayerState.confidence, PlayerState.interview_skill]
	prep_label.add_theme_color_override("font_color", Color(0.36, 0.40, 0.48))

	var start_button := Button.new()
	start_button.text = "Start Interview" if job_id != PlayerState.active_interview_job_id else "Continue"
	start_button.pressed.connect(func(): _start_interview(job_id))

	action_row.add_child(prep_label)
	action_row.add_child(start_button)

	stack.add_child(top_row)
	stack.add_child(detail_label)
	stack.add_child(action_row)
	margin.add_child(stack)
	card.add_child(margin)
	return card


func _interview_brief(job: Dictionary) -> String:
	var required: Array = job.get("required_keywords", [])
	if required.is_empty():
		return "Recruiter screen unlocked. Keep your answers specific and confident."

	return "They will likely ask about: %s." % _join_strings(required.slice(0, 3))


func _start_interview(job_id: String) -> void:
	PlayerState.start_interview(job_id)
	refresh()


func _make_question_card(job_id: String, job: Dictionary) -> PanelContainer:
	var question_index: int = clampi(PlayerState.current_interview_question_index, 0, QUESTIONS.size() - 1)
	var question: Dictionary = QUESTIONS[question_index]

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_style(true))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)

	var title_label := Label.new()
	title_label.text = "Live screen: %s at %s" % [str(job.get("title", "Interview")), str(job.get("company", "Unknown Company"))]
	title_label.add_theme_color_override("font_color", Color(0.05, 0.07, 0.10))

	var progress_label := Label.new()
	progress_label.text = "Question %s / %s   Score %s" % [
		question_index + 1,
		QUESTIONS.size(),
		PlayerState.current_interview_score
	]
	progress_label.add_theme_color_override("font_color", Color(0.30, 0.35, 0.42))

	var prompt_label := Label.new()
	prompt_label.text = str(question.get("prompt", "Question"))
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.add_theme_color_override("font_color", Color(0.14, 0.17, 0.22))

	stack.add_child(title_label)
	stack.add_child(progress_label)
	stack.add_child(prompt_label)

	var answers: Array = question.get("answers", [])
	for answer in answers:
		var answer_data: Dictionary = answer as Dictionary
		var button := Button.new()
		button.text = str(answer_data.get("text", "Answer"))
		button.pressed.connect(func(): _answer_question(job_id, answer_data))
		stack.add_child(button)

	margin.add_child(stack)
	card.add_child(margin)
	return card


func _answer_question(job_id: String, answer: Dictionary) -> void:
	PlayerState.add_interview_score(int(answer.get("score", 0)))
	focus_label.text = str(answer.get("feedback", ""))

	if PlayerState.current_interview_question_index >= QUESTIONS.size() - 1:
		var manager: Node = _game_manager()
		if manager != null:
			manager.call("resolve_interview", job_id, PlayerState.current_interview_score)
		return

	PlayerState.advance_interview_question()
	refresh()


func _focus_text() -> String:
	if PlayerState.unlocked_interviews.is_empty():
		return "Apply to strong matches on the Job Board to unlock interviews."

	if PlayerState.active_interview_job_id == "":
		return "Choose an interview to begin. Prep raises your odds before the full question flow lands."

	var job: Dictionary = jobs_by_id.get(PlayerState.active_interview_job_id, {})
	return "Current focus: %s at %s" % [str(job.get("title", "Interview")), str(job.get("company", "Unknown Company"))]


func _make_card_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.89, 0.96, 0.92) if active else Color(0.96, 0.97, 0.98)
	style.border_color = Color(0.19, 0.58, 0.36) if active else Color(0.72, 0.77, 0.82)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	return style


func _join_strings(values: Array) -> String:
	var text := ""

	for value in values:
		if text != "":
			text += ", "

		text += str(value)

	return text


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.free()


func _toggle_expand() -> void:
	if not _is_expanded:
		_saved_offsets = Vector4(offset_left, offset_top, offset_right, offset_bottom)
		anchor_left = 0.0
		anchor_top = 0.0
		anchor_right = 1.0
		anchor_bottom = 1.0
		offset_left = 8.0
		offset_top = 40.0
		offset_right = -8.0
		offset_bottom = -76.0
	else:
		anchor_left = 0.0
		anchor_top = 0.0
		anchor_right = 0.0
		anchor_bottom = 0.0
		offset_left = _saved_offsets.x
		offset_top = _saved_offsets.y
		offset_right = _saved_offsets.z
		offset_bottom = _saved_offsets.w
	_is_expanded = not _is_expanded


func _on_close_button_pressed() -> void:
	hide()


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")
