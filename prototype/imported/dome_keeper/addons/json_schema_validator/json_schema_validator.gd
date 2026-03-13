extends RefCounted

class_name ImportedJSONSchemaValidator

const ERR_SCHEMA_FALSE: String = "Schema declared as deny all"
const ERR_WRONG_SCHEMA_TYPE: String = "Schema must be bool or object"
const ERR_INVALID_JSON: String = "Invalid JSON payload"


func validate(json_data: String, schema: String) -> String:
	var payload: Variant = JSON.parse_string(json_data)
	if payload == null and json_data.strip_edges() != "null":
		return ERR_INVALID_JSON
	var schema_obj: Variant = JSON.parse_string(schema)
	if typeof(schema_obj) == TYPE_BOOL:
		return "" if bool(schema_obj) else ERR_SCHEMA_FALSE
	if typeof(schema_obj) != TYPE_DICTIONARY:
		return ERR_WRONG_SCHEMA_TYPE
	return _validate_type(payload, schema_obj as Dictionary)


func _validate_type(value: Variant, schema_obj: Dictionary) -> String:
	if not schema_obj.has("type"):
		return ""
	var expected: String = String(schema_obj.get("type", "")).to_lower()
	match expected:
		"object":
			if typeof(value) != TYPE_DICTIONARY:
				return "Type mismatch: expected object"
			return _validate_object(value as Dictionary, schema_obj)
		"array":
			if typeof(value) != TYPE_ARRAY:
				return "Type mismatch: expected array"
			return ""
		"string":
			return "" if typeof(value) == TYPE_STRING else "Type mismatch: expected string"
		"integer":
			return "" if typeof(value) == TYPE_INT else "Type mismatch: expected integer"
		"number":
			return "" if typeof(value) in [TYPE_INT, TYPE_FLOAT] else "Type mismatch: expected number"
		"boolean":
			return "" if typeof(value) == TYPE_BOOL else "Type mismatch: expected boolean"
		"null":
			return "" if value == null else "Type mismatch: expected null"
		_:
			return ""


func _validate_object(obj: Dictionary, schema_obj: Dictionary) -> String:
	var required: Array = schema_obj.get("required", [])
	for req in required:
		var key: String = String(req)
		if not obj.has(key):
			return "Missing required property: %s" % key
	var props: Dictionary = schema_obj.get("properties", {})
	for key in props.keys():
		if not obj.has(key):
			continue
		var nested_schema: Dictionary = props[key]
		var err: String = _validate_type(obj[key], nested_schema)
		if err != "":
			return "%s (%s)" % [err, String(key)]
	return ""

