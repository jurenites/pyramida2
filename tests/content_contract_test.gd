extends SceneTree

const ActionCatalog = preload("res://scripts/gameplay_action_catalog.gd")
const UI_TEXT_CATALOG_PATH := "res://localization/ui_text.csv"

var _failures: Array[String] = []


func _initialize() -> void:
	var english_text_by_key := _test_every_text_key_has_english_wording()
	_test_every_action_has_english_wording(english_text_by_key)
	_test_every_action_has_audio()

	if _failures.is_empty():
		print("PASS: content contracts")
		quit(0)
		return

	printerr("FAIL: content contracts (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)


func _test_every_text_key_has_english_wording() -> Dictionary:
	var english_text_by_key := {}
	var catalog_file := FileAccess.open(UI_TEXT_CATALOG_PATH, FileAccess.READ)
	if catalog_file == null:
		_failures.append("Unable to open %s" % UI_TEXT_CATALOG_PATH)
		return english_text_by_key

	var header := catalog_file.get_csv_line()
	var key_column_index := header.find("keys")
	var english_column_index := header.find("en")
	if key_column_index < 0 or english_column_index < 0:
		_failures.append("UI text catalog must contain keys and en columns")
		return english_text_by_key

	var english_letter := RegEx.create_from_string("[A-Za-z]")
	while catalog_file.get_position() < catalog_file.get_length():
		var row := catalog_file.get_csv_line()
		if row.is_empty():
			continue
		if row.size() != header.size():
			_failures.append("UI text row does not match the header: %s" % str(row))
			continue
		var text_key := row[key_column_index].strip_edges()
		if text_key.is_empty():
			_failures.append("UI text row has no key: %s" % str(row))
			continue
		if english_text_by_key.has(text_key):
			_failures.append("Duplicate UI text key: %s" % text_key)
			continue
		var english_text := row[english_column_index].replace("\\n", "\n").strip_edges()
		english_text_by_key[text_key] = english_text
		if english_text.is_empty():
			_failures.append("UI text key has no English wording: %s" % text_key)
		elif english_letter.search(english_text) == null:
			_failures.append("UI text key has no English letters: %s" % text_key)

	return english_text_by_key


func _test_every_action_has_english_wording(english_text_by_key: Dictionary) -> void:
	if ActionCatalog.DEFINITIONS.is_empty():
		_failures.append("Gameplay action catalog has no registered actions")
		return
	for action_id in _sorted_action_ids():
		var definition: Dictionary = ActionCatalog.DEFINITIONS[action_id]
		var text_key := str(definition.get("text_key", "")).strip_edges()
		if text_key.is_empty():
			_failures.append("Action has no English text key: %s" % action_id)
		elif not english_text_by_key.has(text_key):
			_failures.append("Action %s references missing English text key: %s" % [action_id, text_key])
		elif str(english_text_by_key[text_key]).is_empty():
			_failures.append("Action %s references blank English text key: %s" % [action_id, text_key])


func _test_every_action_has_audio() -> void:
	for action_id in _sorted_action_ids():
		var definition: Dictionary = ActionCatalog.DEFINITIONS[action_id]
		var audio_streams: Variant = definition.get("audio_streams", null)
		if not audio_streams is Array or (audio_streams as Array).is_empty():
			_failures.append("Action has no audio attached: %s" % action_id)
			continue
		for audio_path_value in audio_streams:
			var audio_path := str(audio_path_value)
			if not ResourceLoader.exists(audio_path, "AudioStream"):
				_failures.append("Action %s references missing audio: %s" % [action_id, audio_path])
				continue
			var audio_stream := ResourceLoader.load(audio_path, "AudioStream") as AudioStream
			if audio_stream == null:
				_failures.append("Action %s does not reference an AudioStream: %s" % [action_id, audio_path])


func _sorted_action_ids() -> Array:
	var action_ids := ActionCatalog.DEFINITIONS.keys()
	action_ids.sort()
	return action_ids
