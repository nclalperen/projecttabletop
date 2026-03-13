extends Area3D

@export var player_id: int = 1
@export var tint_color: Color = Color(0.1, 0.7, 0.8, 0.24)

@onready var _mesh_instance: MeshInstance3D = _ensure_mesh()


func _ready() -> void:
	body_entered.connect(_on_hidden_area_body_entered)
	body_exited.connect(_on_hidden_area_body_exited)
	update_player_color()


func _ensure_mesh() -> MeshInstance3D:
	var mesh := get_node_or_null("Mesh") as MeshInstance3D
	if mesh != null:
		return mesh
	mesh = MeshInstance3D.new()
	mesh.name = "Mesh"
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.01, 0.4)
	mesh.mesh = box
	add_child(mesh)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.set_surface_override_material(0, mat)
	return mesh


func update_player_color() -> void:
	var mat: StandardMaterial3D = _mesh_instance.get_active_material(0) as StandardMaterial3D
	if mat == null:
		return
	var next := mat.duplicate() as StandardMaterial3D
	next.albedo_color = tint_color
	_mesh_instance.set_surface_override_material(0, next)


func _on_hidden_area_body_entered(body: Node3D) -> void:
	if body == null:
		return
	var body_owner: int = int(body.get_meta("owner_id", player_id))
	if body_owner != player_id:
		body.visible = false


func _on_hidden_area_body_exited(body: Node3D) -> void:
	if body == null:
		return
	body.visible = true

