class_name BuildInfo
extends RefCounted

## Bump VERSION and refresh the commit/timestamp for every applied chat batch.
const VERSION := "0.0.27"
const GIT_COMMIT := "fc75baa"
const APPLIED_AT_GMT_PLUS_3 := "2026-08-09 22:47 GMT+3"


static func inline_label() -> String:
	return "v%s  ·  %s  ·  %s" % [VERSION, GIT_COMMIT, APPLIED_AT_GMT_PLUS_3]
