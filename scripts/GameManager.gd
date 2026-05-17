extends Node

# GameManager coordinates the overall game loop.
#
# It should handle high-level flow:
# - starting a new run
# - ending the week
# - checking win conditions
# - checking lose conditions
# - asking UI scenes to refresh after state changes
#
# GameManager should not contain every detailed rule. For example, project
# progress, job matching, and interview scoring can move into their own systems
# once those mechanics are built.

signal week_report(title: String, message: String)
signal game_over(won: bool, title: String, message: String)
signal offer_received(job_id: String)

const RENT_PER_WEEK := 135
const FOOD_PER_WEEK := 45
const DEBT_INTEREST := 25
const BURNOUT_DANGER := 82
const OFFER_SCORE_TARGET := 18

var rng := RandomNumberGenerator.new()
var timer_running: bool = false
var _timer_refresh_accumulator: float = 0.0


func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	if not timer_running:
		return

	if PlayerState.has_offer or PlayerState.has_lost:
		return

	if PlayerState.idle_seconds_left <= 0.0:
		return

	PlayerState.idle_seconds_left = maxf(PlayerState.idle_seconds_left - delta, 0.0)
	_timer_refresh_accumulator += delta

	if _timer_refresh_accumulator >= 0.25:
		_timer_refresh_accumulator = 0.0
		PlayerState.state_changed.emit()

	if PlayerState.idle_seconds_left <= 0.0:
		week_report.emit("Week timer expired", "You ran out of time this week. Rent, debt, and burnout still move.")
		end_week()


func start_new_run() -> void:
	PlayerState.reset_run()
	timer_running = true
	_timer_refresh_accumulator = 0.0
	week_report.emit("New run started", "You have 15 weeks to get an offer before graduation pressure wins.")


func end_week() -> void:
	if PlayerState.has_offer or PlayerState.has_lost:
		return

	var expenses: int = RENT_PER_WEEK + FOOD_PER_WEEK
	var debt_payment: int = PlayerState.debt_minimum_payment if PlayerState.debt > 0 else 0
	var total_due: int = expenses + debt_payment

	PlayerState.spend_money(total_due)
	if PlayerState.debt > 0:
		PlayerState.debt = maxi(PlayerState.debt - debt_payment + DEBT_INTEREST, 0)

	_apply_week_pressure()
	var event_text: String = _roll_week_event()
	_check_loss_conditions()
	if PlayerState.has_lost:
		return

	PlayerState.advance_week()
	var report: String = "Paid $%s for survival costs. Build signal, manage burnout, and chase interviews." % total_due
	if event_text != "":
		report += "\n%s" % event_text

	week_report.emit(
		"Week %s begins" % PlayerState.week_num,
		report
	)
	_check_loss_conditions()


func resolve_interview(job_id: String, interview_score: int) -> void:
	if PlayerState.has_offer or PlayerState.has_lost:
		return

	var readiness: int = interview_score + int(PlayerState.interview_skill / 10.0) + int(PlayerState.confidence / 20.0)
	var burnout_penalty: int = int(PlayerState.burnout / 25.0)
	var final_score: int = readiness - burnout_penalty

	if final_score >= OFFER_SCORE_TARGET:
		PlayerState.set_offer(job_id)
		timer_running = false
		offer_received.emit(job_id)
		game_over.emit(true, "Offer secured", "You stayed afloat long enough to turn signal into an offer.")
		return

	PlayerState.add_confidence(-8)
	PlayerState.add_burnout(6)
	PlayerState.finish_interview(job_id)
	week_report.emit(
		"Interview missed",
		"You got feedback, not an offer. Prep more, reduce burnout, and try the next lead."
	)
	_check_loss_conditions()


func _apply_week_pressure() -> void:
	if PlayerState.burnout >= BURNOUT_DANGER:
		PlayerState.add_confidence(-6)
		PlayerState.add_score(-5)
	elif PlayerState.burnout >= 60:
		PlayerState.add_confidence(-3)

	if PlayerState.checking_balance < 100:
		PlayerState.add_burnout(5)
		PlayerState.add_confidence(-4)


func _roll_week_event() -> String:
	var roll: int = rng.randi_range(1, 100)

	if roll <= 16:
		PlayerState.add_money(90)
		PlayerState.add_confidence(4)
		return "A tiny campus gig paid out. +$90, +4 confidence."

	if roll <= 30:
		PlayerState.add_burnout(7)
		return "A surprise life errand ate your evening. +7 burnout."

	if roll <= 42 and PlayerState.resume_keywords.size() >= 4:
		PlayerState.add_application("referral_%s" % PlayerState.week_num)
		PlayerState.add_confidence(5)
		return "Someone noticed your portfolio and asked for your resume. +1 warm lead."

	if roll <= 52 and PlayerState.checking_balance < 120:
		PlayerState.spend_money(35)
		PlayerState.add_burnout(4)
		return "Low balance fee. The bank chose violence. -$35, +4 burnout."

	return ""


func _check_loss_conditions() -> void:
	if PlayerState.checking_balance < -200:
		_lose("Checking account collapsed. The search became impossible to sustain.")
		return

	if PlayerState.burnout >= 100:
		_lose("Burnout hit 100%. You could not keep going.")
		return

	if PlayerState.week_num > PlayerState.max_weeks and not PlayerState.has_offer:
		_lose("Graduation arrived before an offer did.")


func _lose(reason: String) -> void:
	if PlayerState.has_lost:
		return

	PlayerState.set_loss(reason)
	timer_running = false
	game_over.emit(false, "You sank", reason)
