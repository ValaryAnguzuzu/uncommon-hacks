extends PanelContainer

# InterviewPrepWindow lets the player spend action points improving interview skill.
#
# General behavior:
# - Each prep card costs one action point and improves interview_skill, confidence, or both.
# - Cards are locked when action points run out, same as WorkWindow.
# - Stats in the header update on every state_changed so the player can track progress.

const PREP_ACTIONS := [
	{
		"id": "mock_interview",
		"title": "Mock Interview",
		"flavor": "Run through a full question set out loud. Uncomfortable, but it works.",
		"effects": {"interview_skill": 8, "confidence": 4, "burnout": 6}
	},
	{
		"id": "dsa_practice",
		"title": "DSA Practice",
		"flavor": "LeetCode grind. Two pointers, sliding window, the whole ritual.",
		"effects": {"interview_skill": 10, "burnout": 8, "confidence": 2}
	},
	{
		"id": "system_design",
		"title": "System Design Practice",
		"flavor": "Diagram a database, sketch a cache layer, explain tradeoffs to the wall.",
		"effects": {"interview_skill": 7, "confidence": 3, "burnout": 5}
	},
	{
		"id": "company_research",
		"title": "Company Research",
		"flavor": "Read their blog, know their stack, have an answer to 'why us?'",
		"effects": {"confidence": 8, "interview_skill": 3, "burnout": 3}
	},
	{
		"id": "behavioral_prep",
		"title": "Behavioral Prep",
		"flavor": "Star method. Conflict stories. The 'tell me about yourself' draft that actually lands.",
		"effects": {"confidence": 10, "interview_skill": 4, "burnout": 4}
	}
]

@onready var close_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/CloseDot
@onready var zoom_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/ZoomDot
@onready var close_button: Button = $OuterMargin/WindowStack/TitleBar/CloseButton
@onready var skill_label: Label = $OuterMargin/WindowStack/HeaderStrip/HeaderRow/SkillLabel
@onready var confidence_label: Label = $OuterMargin/WindowStack/HeaderStrip/HeaderRow/ConfidenceLabel
@onready var prep_list: VBoxContainer = $OuterMargin/WindowStack/PrepScroll/PrepList

var _used_actions: Dictionary = {}
var _last_week: int = -1
var _is_expanded: bool = false
var _saved_offsets: Vector4 = Vector4.ZERO


func _ready() -> void:
	close_dot.pressed.connect(_on_close_button_pressed)
	zoom_dot.pressed.connect(func(): _toggle_expand())
	close_button.pressed.connect(_on_close_button_pressed)

	var refresh_callable := Callable(self, "refresh")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	refresh()


func refresh() -> void:
	if PlayerState.week_num != _last_week:
		_used_actions.clear()
		_last_week = PlayerState.week_num

	skill_label.text = "Interview Skill: %s%%" % PlayerState.interview_skill
	confidence_label.text = "Confidence: %s%%" % PlayerState.confidence
	confidence_label.add_theme_color_override(
		"font_color",
		Color(0.568627, 0.85098, 0.752941) if PlayerState.action_points_remaining > 0 else Color(0.72, 0.38, 0.32)
	)

	_render_prep_cards()


func _render_prep_cards() -> void:
	_clear_container(prep_list)

	for action in PREP_ACTIONS:
		prep_list.add_child(_make_prep_card(action))


func _make_prep_card(action: Dictionary) -> PanelContainer:
	var action_id := str(action.get("id", ""))
	var used: bool = _used_actions.get(action_id, false)
	var out_of_ap: bool = PlayerState.action_points_remaining <= 0
	var locked: bool = used or out_of_ap

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_style(used))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)

	var outer_stack := VBoxContainer.new()
	outer_stack.add_theme_constant_override("separation", 8)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)

	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 4)

	var title_label := Label.new()
	title_label.text = str(action.get("title", "Prep"))
	title_label.add_theme_color_override(
		"font_color",
		Color(0.68, 0.70, 0.73) if used else Color(0.92, 0.94, 0.96)
	)

	var flavor_label := Label.new()
	flavor_label.text = str(action.get("flavor", ""))
	flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor_label.add_theme_color_override("font_color", Color(0.48, 0.52, 0.58))

	text_stack.add_child(title_label)
	text_stack.add_child(flavor_label)

	var do_it_button := Button.new()
	do_it_button.text = "Done" if used else ("No AP" if out_of_ap else "Practice")
	do_it_button.disabled = locked
	do_it_button.custom_minimum_size = Vector2(90, 0)
	do_it_button.pressed.connect(func(): _execute_prep(action))

	top_row.add_child(text_stack)
	top_row.add_child(do_it_button)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 6)

	var effects: Dictionary = action.get("effects", {})
	for key in effects:
		badge_row.add_child(_make_badge(key, int(effects[key])))

	outer_stack.add_child(top_row)
	outer_stack.add_child(badge_row)
	margin.add_child(outer_stack)
	card.add_child(margin)
	return card


func _execute_prep(action: Dictionary) -> void:
	var action_id := str(action.get("id", ""))
	if action_id == "" or _used_actions.get(action_id, false):
		return
	if PlayerState.action_points_remaining <= 0:
		return

	var effects: Dictionary = action.get("effects", {})

	if effects.has("interview_skill"):
		PlayerState.add_interview_skill(int(effects["interview_skill"]))
	if effects.has("confidence"):
		PlayerState.add_confidence(int(effects["confidence"]))
	if effects.has("burnout"):
		PlayerState.add_burnout(int(effects["burnout"]))
	if effects.has("score"):
		PlayerState.add_score(int(effects["score"]))

	PlayerState.spend_action_point()
	_used_actions[action_id] = true


func _make_badge(key: String, value: int) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _make_badge_style(key, value))

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 8)
	inner.add_theme_constant_override("margin_right", 8)
	inner.add_theme_constant_override("margin_top", 3)
	inner.add_theme_constant_override("margin_bottom", 3)

	var label := Label.new()
	label.text = _format_effect(key, value)
	label.add_theme_color_override("font_color", _badge_text_color(key, value))

	inner.add_child(label)
	badge.add_child(inner)
	return badge


func _format_effect(key: String, value: int) -> String:
	match key:
		"interview_skill":
			return "+%s Interview" % value
		"confidence":
			return ("%s%s Confidence" % ["+" if value > 0 else "", value])
		"burnout":
			return ("%s%s Burnout" % ["+" if value > 0 else "", value])
		"score":
			return "+%s Score" % value
	return "%s%s %s" % ["+" if value > 0 else "", value, key.capitalize()]


func _badge_text_color(key: String, value: int) -> Color:
	match key:
		"interview_skill":
			return Color(0.18, 0.52, 0.56)
		"confidence":
			return Color(0.22, 0.48, 0.72) if value > 0 else Color(0.62, 0.28, 0.28)
		"burnout":
			return Color(0.72, 0.38, 0.18) if value > 0 else Color(0.18, 0.55, 0.38)
		"score":
			return Color(0.48, 0.30, 0.72)
	return Color(0.48, 0.52, 0.58)


func _make_badge_style(key: String, value: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	match key:
		"interview_skill":
			style.bg_color = Color(0.82, 0.94, 0.96)
			style.border_color = Color(0.34, 0.68, 0.72)
		"confidence":
			if value > 0:
				style.bg_color = Color(0.84, 0.90, 0.98)
				style.border_color = Color(0.42, 0.60, 0.88)
			else:
				style.bg_color = Color(0.96, 0.86, 0.86)
				style.border_color = Color(0.78, 0.42, 0.42)
		"burnout":
			if value > 0:
				style.bg_color = Color(0.98, 0.90, 0.82)
				style.border_color = Color(0.82, 0.58, 0.32)
			else:
				style.bg_color = Color(0.84, 0.96, 0.90)
				style.border_color = Color(0.38, 0.72, 0.52)
		"score":
			style.bg_color = Color(0.92, 0.86, 0.98)
			style.border_color = Color(0.62, 0.42, 0.88)
		_:
			style.bg_color = Color(0.88, 0.90, 0.93)
			style.border_color = Color(0.62, 0.65, 0.70)

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style


func _make_card_style(used: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.11, 0.13) if used else Color(0.14, 0.16, 0.19)
	style.border_color = Color(0.24, 0.27, 0.32) if used else Color(0.32, 0.36, 0.44)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	return style


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


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.free()


func _on_close_button_pressed() -> void:
	hide()
