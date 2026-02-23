# Copyright (c) 2023-present Delano Lourenco
# https://github.com/3ddelano/epic-online-services-godot/
# MIT License
## Runtime controller for Epic Online Services. This is available as the EOSGRuntime autoload.
class_name EOSGRuntime
extends Node


## The Product User ID of the most recent logged in user.
var local_product_user_id: String

## The Epic Account ID of the most recent logged in user.
var local_epic_account_id: String
var _platform_created := false


func _ready() -> void:
	if not _has_ieos():
		return
	var platform := get_node_or_null("/root/HPlatform")
	if platform != null and platform.has_signal("platform_created"):
		platform.platform_created.connect(func() -> void:
			_platform_created = true
		)
	if platform != null and platform.has_signal("platform_initialized"):
		platform.platform_initialized.connect(func() -> void:
			_platform_created = false
		)
	IEOS.auth_interface_login_callback.connect(func (data: Dictionary):
		if data.local_user_id != "":
			local_epic_account_id = data.local_user_id
	)

	IEOS.connect_interface_login_callback.connect(func (data: Dictionary):
		if data.local_user_id != "":
			local_product_user_id = data.local_user_id
	)

	IEOS.auth_interface_logout_callback.connect(_on_logout)


func _on_logout(data: Dictionary):
	local_epic_account_id = ""
	local_product_user_id = ""


func _process(_delta: float):
	if not _has_ieos():
		return
	# Avoid ticking before HPlatform creates EOS platform handle.
	if not _platform_created:
		return
	IEOS.tick()


func _has_ieos() -> bool:
	# `IEOS` is supplied by the EOSG GDExtension singleton. During shutdown, the class
	# may still exist while the singleton is already torn down, so gate on singleton availability.
	return Engine.has_singleton("IEOS")
