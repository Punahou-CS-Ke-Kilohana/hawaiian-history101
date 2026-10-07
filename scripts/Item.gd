class_name Item
extends RigidBody3D


func pickup(player):
	player.equip_item(self)
