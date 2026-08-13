extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const UIText = preload("res://scripts/ui_text_catalog.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	_check(
		UIText.text(UIText.CITIZEN_BUILDING_STATUS_TEXT) == "Building",
		"Building labour status is missing from the runtime translation"
	)
	await process_frame

	var citizens: Array = game.get("_citizens")
	var citizen := citizens[0] as Citizen
	var pile := game.get("_starting_pile") as PileStorage
	var construction_site := SupportConstructionSite.new()
	game.add_child(construction_site)
	construction_site.global_position = Vector3(3.5, 0.0, 3.5)
	var construction_sites: Array = game.get("_construction_sites")
	construction_sites.append(construction_site)
	game.call("_select_building", construction_site)
	game.call("_update_selected_construction_inspector")
	_check(bool(game.get("_build_mode")), "Selecting a Construction Site did not enter Building Mode")
	var build_menu := game.get("_build_menu") as Control
	_check(build_menu.visible, "Selecting a Construction Site did not reveal the Building menu")
	var planned_posts := construction_site.find_children(
		"PlannedSupportPost*",
		"MeshInstance3D",
		true,
		false
	)
	_check(planned_posts.size() == 4, "Support does not expose its complete planned shape")
	for planned_post_value in planned_posts:
		var planned_post := planned_post_value as MeshInstance3D
		_check(planned_post.visible, "Selected Support has a hidden planned component")
		var planned_material := planned_post.material_override as StandardMaterial3D
		_check(
			planned_material.albedo_color.is_equal_approx(
				Color(0.5019608, 0.5019608, 0.5019608, 0.5)
			),
			"Support planned component is not the required 50%-opaque gray"
		)
	var planned_bounds: AABB = game.call("_world_visual_bounds", construction_site)
	_check(
		planned_bounds.end.y > 0.95 and planned_bounds.end.y <= 1.05,
		"Support asset does not remain synchronized to one standard World Unit"
	)
	var selection_outline := game.get("_selection_outline_root") as MultiMeshInstance3D
	game.call("_update_world_selection_outline")
	var mesh_outlines: Array = game.get("_selection_mesh_outlines")
	_check(not selection_outline.visible, "Selected Construction Site kept the old cube-edge outline")
	_check(not mesh_outlines.is_empty(), "Selected Construction Site has no white mesh outline")
	var inspector := game.get("_construction_inspector") as ConstructionInspector
	_check(inspector.visible, "Selected Construction Site does not show its progress readout")
	_check(
		is_equal_approx(inspector.total_progress_bar().size.x, 96.0),
		"Four three-second Logs do not create a 96-pixel total progress bar"
	)
	_check(
		inspector.material_readout("log").number_label().text == "0/4",
		"Construction material Icon Number does not begin at 0/4"
	)
	_check(
		inspector.material_readout("log").scale_mode() == IconNumber.ScaleMode.FULL_SCALE,
		"Construction material does not use Full Scale Icon Number"
	)
	_check(
		construction_site.find_children("*", "Label3D", true, false).is_empty(),
		"Construction Site still creates floating progress text"
	)
	_check(
		str(game.call("_hover_display_name", construction_site, null)) == "Support 0/4 logs",
		"Planned Support hover does not show material progress"
	)

	var initial_logs := pile.stored_logs
	game.call("_handle_fetch_log_arrival", citizen, {
		"source_pile": pile,
		"construction_site": construction_site,
	})
	_check(pile.stored_logs == initial_logs - 1, "Citizen did not take exactly one building block")
	_check(
		str(citizen.task.get("kind", "")) == GameplayActionCatalog.DELIVER_LOG,
		"Fetched building block was not assigned for delivery"
	)

	game.call("_handle_deliver_log_arrival", citizen, citizen.task.duplicate())
	_check(construction_site.delivered_logs == 0, "Building block was applied immediately on arrival")
	_check(
		str(citizen.task.get("kind", "")) == GameplayActionCatalog.APPLY_BUILDING_BLOCK,
		"Citizen did not begin building labour on arrival"
	)
	var active_work: Dictionary = game.get("_active_work")
	var work: Dictionary = active_work[citizen]
	var labour_records: Dictionary = game.get("_labour_records")
	var work_record: Dictionary = labour_records[str(work.get("labour_key", ""))]
	var personal_progress := work_record.get("bar") as LabourProgressBar
	_check(
		not personal_progress.visible,
		"Selected construction displays a separate per-Citizen progress bar"
	)

	game.call("_update_labour", 1.5)
	game.call("_update_selected_construction_inspector")
	_check(
		absf(inspector.total_progress_bar().progress_ratio() - 0.125) < 0.002,
		"Partial Citizen labour is missing from total construction progress"
	)
	game.call("_update_labour", 1.49)
	_check(construction_site.delivered_logs == 0, "Building block was applied before three seconds")
	game.call("_update_labour", 0.01)
	game.call("_update_selected_construction_inspector")
	_check(construction_site.delivered_logs == 1, "Three seconds of labour did not apply one building block")
	_check(
		absf(inspector.total_progress_bar().progress_ratio() - 0.25) < 0.002,
		"One installed Log does not report one quarter total construction progress"
	)
	_check(
		inspector.material_readout("log").number_label().text == "1/4",
		"Construction material Icon Number did not update to 1/4"
	)
	var visible_planned_posts := 0
	for planned_post_value in planned_posts:
		if (planned_post_value as MeshInstance3D).visible:
			visible_planned_posts += 1
	_check(visible_planned_posts == 3, "Installed Log did not replace exactly one planned component")
	_check(pile.stored_logs == initial_logs - 1, "Completed construction returned or consumed extra blocks")
	_check(
		str(game.call("_hover_display_name", construction_site, null)) == "Support 1/4 logs",
		"Construction hover did not update after applying a building block"
	)
	for _remaining_log in 3:
		construction_site.deliver_log()
	game.call("_update_selected_construction_inspector")
	_check(not inspector.visible, "Completed Support still shows Construction Site progress")
	_check(
		str(game.call("_hover_display_name", construction_site, null)) == "Support",
		"Completed Support hover must show only the building name"
	)
	_check(construction_site.is_complete(), "Fully supplied Support still reports as a Construction Site")
	game.call("_order_enter_completed_building", citizen, construction_site)
	_check(
		str(citizen.task.get("kind", "")) == GameplayActionCatalog.MOVE,
		"Completed building click did not issue movement into the building"
	)
	_check(
		citizen.task.get("target") == construction_site,
		"Completed building movement was redirected to another Construction Site"
	)
	_check(
		citizen.work_assignment.is_empty(),
		"Completed building movement incorrectly created a construction assignment"
	)

	if _failures.is_empty():
		print("PASS: construction labour")
		quit(0)
		return
	printerr("FAIL: construction labour (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
