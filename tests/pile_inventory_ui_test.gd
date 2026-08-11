extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _resource_count_text(inventory_row: HBoxContainer, resource_kind: String) -> String:
	var count_label := inventory_row.get_node(
		"ResourceCard_%s/CardContents/ResourceCount" % resource_kind
	) as Label
	return count_label.text


func _run() -> void:
	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var starting_pile := game.get("_starting_pile") as PileStorage
	starting_pile.store_calories(3)
	starting_pile.store_resource("stone", 2)
	var no_citizens: Array[Citizen] = []
	game.call("_set_selected_citizens", no_citizens)
	game.call("_select_world_object", starting_pile)
	game.call("_update_selected_pile_inventory")

	var inventory_row := game.find_child("SelectedPileInventory", true, false) as HBoxContainer
	_check(inventory_row.visible, "Selected Pile inventory is not visible")
	_check(_resource_count_text(inventory_row, "log") == "6", "Log card does not show the selected Pile count")
	_check(_resource_count_text(inventory_row, "calories") == "3", "Calories card has the wrong count")
	_check(_resource_count_text(inventory_row, "stone") == "2", "Extensible resource card has the wrong count")

	var log_card := inventory_row.get_node("ResourceCard_log") as PanelContainer
	var card_contents := log_card.get_node("CardContents") as IconNumber
	var log_icon := log_card.get_node("CardContents/ResourceIcon") as Button
	var card_style := log_card.get_theme_stylebox("panel") as StyleBoxFlat
	_check(log_icon.custom_minimum_size == Vector2(10.0, 10.0), "Pile resource icon is not quarter-scale")
	_check(card_contents.scale_mode() == IconNumber.ScaleMode.COMPACT, "Pile resource does not use Compact Icon Number")
	_check(card_style.border_width_left == 2, "Resource card does not have its dedicated outline")

	starting_pile.store_log()
	game.call("_update_selected_pile_inventory")
	_check(_resource_count_text(inventory_row, "log") == "7", "Selected Pile panel did not update live")

	var other_pile := PileStorage.new()
	other_pile.configure_starting_inventory(1)
	other_pile.store_calories(8)
	game.add_child(other_pile)
	game.call("_select_world_object", other_pile)
	game.call("_update_selected_pile_inventory")
	_check(_resource_count_text(inventory_row, "log") == "1", "Panel mixed Logs from two different Piles")
	_check(_resource_count_text(inventory_row, "calories") == "8", "Panel mixed Calories from two different Piles")
	_check(not inventory_row.has_node("ResourceCard_stone"), "Panel retained a resource from the previous Pile")

	game.call("_clear_object_selection")
	game.call("_update_selected_pile_inventory")
	_check(not inventory_row.visible, "Pile inventory remains visible after deselection")

	if _failures.is_empty():
		print("PASS: selected Pile inventory UI")
		quit(0)
		return
	printerr("FAIL: selected Pile inventory UI (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
