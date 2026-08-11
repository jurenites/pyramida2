class_name BuildInfo
extends RefCounted

## Bump VERSION and refresh the commit/timestamp for every applied chat batch.
const VERSION := "0.0.50"
const GIT_COMMIT := "c836086"
const APPLIED_AT_GMT_PLUS_3 := "2026-08-11 16:57 GMT+3"


static func inline_label() -> String:
	return "v%s  ·  %s  ·  %s" % [VERSION, GIT_COMMIT, APPLIED_AT_GMT_PLUS_3]
