class_name GameplayActionCatalog
extends RefCounted

const UIText = preload("res://scripts/ui_text_catalog.gd")

const MOVE := "move"
const CHOP_TREE := "chop"
const HARVEST_BUSH := "harvest"
const COLLECT_CACTUS := "collect_cactus"
const EXCAVATE := "excavate"
const FETCH_LOG := "fetch_log"
const DELIVER_LOG := "deliver_log"

## Every player-ordered Citizen action belongs here. The content contract tests
## require a readable English text key and at least one loadable AudioStream for
## each definition. Empty arrays deliberately identify unfinished audio work.
const DEFINITIONS := {
	MOVE: {
		"text_key": UIText.CITIZEN_WALKING_STATUS_TEXT,
		"audio_streams": [],
	},
	CHOP_TREE: {
		"text_key": UIText.CITIZEN_CUTTING_TREE_STATUS_TEXT,
		"audio_streams": [],
	},
	HARVEST_BUSH: {
		"text_key": UIText.CITIZEN_HARVESTING_BUSH_STATUS_TEXT,
		"audio_streams": [],
	},
	COLLECT_CACTUS: {
		"text_key": UIText.CITIZEN_COLLECTING_CACTUS_STATUS_TEXT,
		"audio_streams": [],
	},
	EXCAVATE: {
		"text_key": UIText.CITIZEN_DIGGING_STATUS_TEXT,
		"audio_streams": [],
	},
	FETCH_LOG: {
		"text_key": UIText.CITIZEN_FETCHING_LOG_STATUS_TEXT,
		"audio_streams": [],
	},
	DELIVER_LOG: {
		"text_key": UIText.CITIZEN_CARRYING_LOG_STATUS_TEXT,
		"audio_streams": [],
	},
}


static func definition(action_id: String) -> Dictionary:
	if not DEFINITIONS.has(action_id):
		return {}
	return (DEFINITIONS[action_id] as Dictionary).duplicate(true)
