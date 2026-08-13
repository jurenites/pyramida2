class_name BuildInfo
extends RefCounted

## Bump VERSION and refresh the commit/timestamp for every applied chat batch.
const VERSION := "0.0.62"
const GIT_COMMIT := "df2a98c"
const APPLIED_AT_GMT_PLUS_3 := "2026-08-13 16:33 GMT+3"


static func inline_label() -> String:
	return "v%s  ·  %s  ·  %s" % [VERSION, GIT_COMMIT, APPLIED_AT_GMT_PLUS_3]
