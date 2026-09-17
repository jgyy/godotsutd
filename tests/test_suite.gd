class_name TestSuite
extends RefCounted

var tree: SceneTree
var failures: Array[String] = []


func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])


func assert_approx(actual: float, expected: float, msg: String = "") -> void:
	if not is_equal_approx(actual, expected):
		failures.append("%s: expected ~%s, got %s" % [msg, str(expected), str(actual)])
