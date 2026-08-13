class_name AppliedLabour
extends RefCounted

const GameplaySettingsScript = preload("res://scripts/gameplay_settings.gd")

var required_seconds: float
var applied_seconds := 0.0
var _contributors: Dictionary = {}
var _interrupted_visibility_remaining := 0.0


func _init(next_required_seconds: float) -> void:
	required_seconds = maxf(next_required_seconds, 0.001)


func resume(contributor_id: int) -> void:
	_contributors[contributor_id] = true
	_interrupted_visibility_remaining = GameplaySettingsScript.INTERRUPTED_LABOUR_VISIBILITY_SECONDS


func apply(contributor_id: int, delta: float) -> bool:
	resume(contributor_id)
	applied_seconds = minf(required_seconds, applied_seconds + maxf(delta, 0.0))
	return is_complete()


func interrupt(contributor_id: int) -> void:
	_contributors.erase(contributor_id)
	if _contributors.is_empty():
		_interrupted_visibility_remaining = GameplaySettingsScript.INTERRUPTED_LABOUR_VISIBILITY_SECONDS


func update_interruption(delta: float) -> void:
	if not _contributors.is_empty():
		return
	_interrupted_visibility_remaining = maxf(
		0.0,
		_interrupted_visibility_remaining - maxf(delta, 0.0)
	)


func progress_ratio() -> float:
	return clampf(applied_seconds / required_seconds, 0.0, 1.0)


func remaining_seconds() -> float:
	return maxf(0.0, required_seconds - applied_seconds)


func is_complete() -> bool:
	return applied_seconds >= required_seconds


func is_being_applied() -> bool:
	return not _contributors.is_empty()


func should_be_visible() -> bool:
	return is_being_applied() or _interrupted_visibility_remaining > 0.0
