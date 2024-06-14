@tool
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  ##
##  AES implementation in GDscript                       (c) Aleksander Haugas 2024 / MIT Licence ##
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  ##
extends EditorPlugin

func _enter_tree():
	# Initialization of the plugin goes here.
	# Add the new type with a name, a parent type, a script and an icon.
	add_custom_type("CryptoLib", "Node", preload("res://addons/cryptolib/aes/aes256.gd"), preload("res://addons/cryptolib/icon.png"))
	pass
