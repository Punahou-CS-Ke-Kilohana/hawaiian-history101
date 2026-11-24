extends Control

@onready var quest_label: Label = $ColorRect/Quest_description

func _ready():
	QuestManager.quest_updated.connect(update_quest)

	update_quest(QuestManager.current_quest)

func update_quest(quest: Dictionary):
	quest_label.text = quest["description"]
