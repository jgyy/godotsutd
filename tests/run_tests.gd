extends SceneTree
## Headless test runner: godot --headless -s tests/run_tests.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var total := 0
	var failed := 0
	var dir := DirAccess.open("res://tests")
	var files: Array[String] = []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_suite.gd":
			files.append(f)
	files.sort()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		var suite: TestSuite = script.new()
		suite.tree = self
		for m in script.get_script_method_list():
			if not m.name.begins_with("test_"):
				continue
			total += 1
			suite.failures.clear()
			await suite.call(m.name)
			await process_frame
			if suite.failures.is_empty():
				print("PASS %s.%s" % [f, m.name])
			else:
				failed += 1
				for msg in suite.failures:
					print("FAIL %s.%s: %s" % [f, m.name, msg])
	print("%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)
