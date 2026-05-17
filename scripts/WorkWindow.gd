extends PanelContainer

# WorkWindow is the weekly action planner.
#
# General behavior:
# - Each action card shows name, flavor text, effect badges, and a Do It button.
# - Players have a limited number of action points per week (from PlayerState).
# - Spending an action point locks out further actions until the next week.
# - When the week advances, used actions and AP are reset via PlayerState.advance_week().
# - Effect badges are color-coded: green = good, orange/red = burnout cost, blue = apps.

const ACTIONS := [
	{
		"id": "blast_applications",
		"title": "Blast Applications",
		"flavor": "Spray and pray. Send it all. The numbers game is undefeated.",
		"effects": {"applications": 5, "burnout": 12, "confidence": -5, "score": 10}
	},
	{
		"id": "side_gig",
		"title": "Side Gig",
		"flavor": "DoorDash, tutoring, Fiverr — whatever keeps the lights on this week.",
		"effects": {"money": 180, "burnout": 8, "confidence": -2, "score": 5}
	},
	{
		"id": "network",
		"title": "Network",
		"flavor": "LinkedIn DMs, alumni coffee chats. Awkward but sometimes it works.",
		"effects": {"confidence": 8, "burnout": 4, "score": 8}
	},
	{
		"id": "rest",
		"title": "Rest",
		"flavor": "Close the laptop. Watch something dumb. You are burning out in real time.",
		"effects": {"burnout": -18, "confidence": 4}
	},
	{
		"id": "coffee_chat",
		"title": "Coffee Chat",
		"flavor": "Book a 15-min call with someone in the field. They have context you don't.",
		"effects": {"confidence": 5, "interview_skill": 4, "burnout": 3, "score": 5}
	},
	{
		"id": "polish_resume",
		"title": "Polish Resume",
		"flavor": "Verb tightening, tailoring, ATS formatting. Small details, real signal.",
		"effects": {"resume_score": 15, "confidence": 3, "burnout": 4, "score": 5}
	}
]

@onready var close_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/CloseDot
@onready var zoom_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/ZoomDot
@onready var close_button: Button = $OuterMargin/WindowStack/TitleBar/CloseButton
@onready var week_label: Label = $OuterMargin/WindowStack/HeaderStrip/HeaderRow/WeekLabel
@onready var ap_label: Label = $OuterMargin/WindowStack/HeaderStrip/HeaderRow/APLabel
@onready var action_list: VBoxContainer = $OuterMargin/WindowStack/ActionScroll/ActionList

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

	week_label.text = "Week %s / %s" % [PlayerState.week_num, PlayerState.max_weeks]

	var ap := PlayerState.action_points_remaining
	ap_label.text = "%s Action%s Left" % [ap, "" if ap == 1 else "s"]
	ap_label.add_theme_color_override(
		"font_color",
		Color(0.568627, 0.85098, 0.752941) if ap > 0 else Color(0.72, 0.38, 0.32)
	)

	_render_actions()


func _render_actions() -> void:
	_clear_container(action_list)

	for action in ACTIONS:
		action_list.add_child(_make_action_card(action))


func _make_action_card(action: Dictionary) -> PanelContainer:
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
	title_label.text = str(action.get("title", "Action"))
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
	do_it_button.text = "Done" if used else ("No AP" if out_of_ap else "Do It")
	do_it_button.disabled = locked
	do_it_button.custom_minimum_size = Vector2(80, 0)
	do_it_button.pressed.connect(func(): _execute_action(action))

	top_row.add_child(text_stack)
	top_row.add_child(do_it_button)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 6)

	var effects: Dictionary = action.get("effects", {})
	for key in effects:
		var value: int = int(effects[key])
		badge_row.add_child(_make_effect_badge(key, value))

	outer_stack.add_child(top_row)
	outer_stack.add_child(badge_row)
	margin.add_child(outer_stack)
	card.add_child(margin)
	return card


func _make_effect_badge(key: String, value: int) -> PanelContainer:
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
		"money":
			return "+$%s" % value
		"burnout":
			return ("%s%s Burnout" % ["+" if value > 0 else "", value])
		"confidence":
			return ("%s%s Confidence" % ["+" if value > 0 else "", value])
		"applications":
			return "+%s Apps" % value
		"score":
			return "+%s Score" % value
		"resume_score":
			return "+%s Resume" % value
		"interview_skill":
			return "+%s Interview" % value
	return "%s%s %s" % ["+" if value > 0 else "", value, key.capitalize()]


func _badge_text_color(key: String, value: int) -> Color:
	match key:
		"money":
			return Color(0.12, 0.52, 0.28)
		"burnout":
			return Color(0.72, 0.38, 0.18) if value > 0 else Color(0.18, 0.55, 0.38)
		"confidence":
			return Color(0.22, 0.48, 0.72) if value > 0 else Color(0.62, 0.28, 0.28)
		"applications":
			return Color(0.28, 0.42, 0.72)
		"score", "resume_score":
			return Color(0.48, 0.30, 0.72)
		"interview_skill":
			return Color(0.18, 0.52, 0.56)
	return Color(0.48, 0.52, 0.58)


func _make_badge_style(key: String, value: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	match key:
		"money":
			style.bg_color = Color(0.82, 0.96, 0.88)
			style.border_color = Color(0.42, 0.78, 0.58)
		"burnout":
			if value > 0:
				style.bg_color = Color(0.98, 0.90, 0.82)
				style.border_color = Color(0.82, 0.58, 0.32)
			else:
				style.bg_color = Color(0.84, 0.96, 0.90)
				style.border_color = Color(0.38, 0.72, 0.52)
		"confidence":
			if value > 0:
				style.bg_color = Color(0.84, 0.90, 0.98)
				style.border_color = Color(0.42, 0.60, 0.88)
			else:
				style.bg_color = Color(0.96, 0.86, 0.86)
				style.border_color = Color(0.78, 0.42, 0.42)
		"applications":
			style.bg_color = Color(0.84, 0.88, 0.98)
			style.border_color = Color(0.42, 0.52, 0.82)
		"score", "resume_score":
			style.bg_color = Color(0.92, 0.86, 0.98)
			style.border_color = Color(0.62, 0.42, 0.88)
		"interview_skill":
			style.bg_color = Color(0.82, 0.94, 0.96)
			style.border_color = Color(0.34, 0.68, 0.72)
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


func _execute_action(action: Dictionary) -> void:
	var action_id := str(action.get("id", ""))
	if action_id == "" or _used_actions.get(action_id, false):
		return
	if PlayerState.action_points_remaining <= 0:
		return

	var effects: Dictionary = action.get("effects", {})
	# Mark the card immediately. PlayerState helpers emit state_changed, which
	# redraws this window while the click handler is still running. Locking first
	# makes the action feel like it registers on the first click.
	_used_actions[action_id] = true

	if effects.has("money"):
		PlayerState.add_money(int(effects["money"]))
	if effects.has("burnout"):
		PlayerState.add_burnout(int(effects["burnout"]))
	if effects.has("confidence"):
		PlayerState.add_confidence(int(effects["confidence"]))
	if effects.has("score"):
		PlayerState.add_score(int(effects["score"]))
	if effects.has("resume_score"):
		PlayerState.add_resume_score(int(effects["resume_score"]))
	if effects.has("interview_skill"):
		PlayerState.add_interview_skill(int(effects["interview_skill"]))
	if effects.has("applications"):
		for _i in range(int(effects["applications"])):
			PlayerState.add_application()

	PlayerState.spend_action_point()
	refresh()


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


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
