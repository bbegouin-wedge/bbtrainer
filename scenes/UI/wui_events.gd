class_name WelcomUIEvents
extends Control

signal goJoinRoom
signal goCreateRoom
signal goWelcome

func activateJoinRoom():
	goJoinRoom.emit()
	
func activateCreateRoom():
	goCreateRoom.emit()
	
func activateWelcome():
	goWelcome.emit()
