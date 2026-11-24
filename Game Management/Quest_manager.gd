extends Node

signal quest_updated(quest: Dictionary)

var current_quest_number: int = 1

var current_quest: Dictionary = {
	"title": "",
	"description": "No quest yet",
	"active": false
}


func give_quest(quest_number: int, title: String, description: String) -> void:
	if quest_number != current_quest_number:
		print("Wrong quest number!")
		return

	if current_quest["active"]:
		print("A quest is already active!")
		return

	current_quest = {
		"title": title,
		"description": description,
		"active": true
	}

	quest_updated.emit(current_quest)


func complete_quest() -> void:
	if not current_quest["active"]:
		return

	current_quest_number += 1

	current_quest = {
		"title": "",
		"description": "No quest yet",
		"active": false
	}

	quest_updated.emit(current_quest)
