@icon("res://icon.svg")
extends Node

class_name ImportedThreadPool

signal task_finished(task_tag)
signal task_discarded(task)

@export var discard_finished_tasks: bool = true
@export var worker_count: int = 2

var _tasks: Array = []
var _tasks_lock: Mutex = Mutex.new()
var _tasks_wait: Semaphore = Semaphore.new()
var _finished_tasks: Array = []
var _finished_lock: Mutex = Mutex.new()
var _pool: Array[Thread] = []
var _started: bool = false
var _finished: bool = false


func _ready() -> void:
	_create_pool()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_wait_for_shutdown()

func submit_task(instance: Object, method: StringName, parameter = null, task_tag = null, no_argument: bool = false, array_argument: bool = false) -> void:
	if _finished:
		return
	_enqueue_task(_Task.new(instance, method, parameter, task_tag, no_argument, array_argument))


func submit_task_unparameterized(instance: Object, method: StringName, task_tag = null) -> void:
	submit_task(instance, method, null, task_tag, true, false)


func submit_task_array_parameterized(instance: Object, method: StringName, parameter: Array, task_tag = null) -> void:
	submit_task(instance, method, parameter, task_tag, false, true)


func fetch_finished_tasks() -> Array:
	_finished_lock.lock()
	var result: Array = _finished_tasks
	_finished_tasks = []
	_finished_lock.unlock()
	return result


func fetch_finished_tasks_by_tag(tag) -> Array:
	_finished_lock.lock()
	var result: Array = []
	var keep: Array = []
	for task in _finished_tasks:
		if task.tag == tag:
			result.append(task)
		else:
			keep.append(task)
	_finished_tasks = keep
	_finished_lock.unlock()
	return result


func shutdown() -> void:
	_finished = true
	for _i in _pool.size():
		_tasks_wait.post()
	_tasks_lock.lock()
	_tasks.clear()
	_tasks_lock.unlock()


func _process(_delta: float) -> void:
	if discard_finished_tasks:
		return
	for task in fetch_finished_tasks():
		emit_signal("task_finished", task.tag)


func _enqueue_task(task: _Task) -> void:
	_tasks_lock.lock()
	_tasks.push_front(task)
	_tasks_lock.unlock()
	_tasks_wait.post()
	_start_if_needed()


func _create_pool() -> void:
	_pool.clear()
	for _i in range(maxi(1, worker_count)):
		_pool.append(Thread.new())


func _start_if_needed() -> void:
	if _started:
		return
	for thread in _pool:
		thread.start(Callable(self, "_execute_tasks"))
		_started = true


func _drain_task() -> _Task:
	_tasks_lock.lock()
	var result: _Task = null
	if _tasks.is_empty():
		result = _Task.new(self, &"_noop", null, null, true, false)
		result.tag = result
	else:
		result = _tasks.pop_back()
	_tasks_lock.unlock()
	return result


func _execute_tasks() -> void:
	while not _finished:
		_tasks_wait.wait()
		if _finished:
			return
		var task: _Task = _drain_task()
		task.execute()
		if task.tag is _Task:
			continue
		if discard_finished_tasks:
			call_deferred("emit_signal", "task_discarded", task)
		else:
			_finished_lock.lock()
			_finished_tasks.append(task)
			_finished_lock.unlock()


func _wait_for_shutdown() -> void:
	shutdown()
	for thread in _pool:
		if thread.is_started():
			thread.wait_to_finish()


func _noop() -> void:
	OS.delay_msec(1)


class _Task:
	var target_instance: Object
	var target_method: StringName
	var target_argument
	var result
	var tag
	var _no_argument: bool
	var _array_argument: bool

	func _init(instance: Object, method: StringName, parameter, task_tag, no_argument: bool, array_argument: bool):
		target_instance = instance
		target_method = method
		target_argument = parameter
		tag = task_tag
		_no_argument = no_argument
		_array_argument = array_argument

	func execute() -> void:
		if target_instance == null or not is_instance_valid(target_instance):
			return
		if _no_argument:
			result = target_instance.call(target_method)
		elif _array_argument:
			result = target_instance.callv(target_method, target_argument)
		else:
			result = target_instance.call(target_method, target_argument)
