extends Reference

var _items = []
var _priorities = []

func _init():
	pass

func push(item, priority):
	_items.append(item)
	_priorities.append(priority)
	_sift_up(_items.size() - 1)

func pop():
	if _items.is_empty():
		return null

	if _items.size() == 1:
		_priorities.clear()
		return _items.pop_front()

	var result = _items[0]
	_items[0] = _items.pop_back()
	_priorities[0] = _priorities.pop_back()
	_sift_down(0)
	return result

func top():
	if _items.is_empty():
		return null
	return _items[0]

func is_empty():
	return _items.is_empty()

func remove(item):
	var index = _find_item_index(item)
	if index == -1:
		return false
	
	# 如果移除的是最后一个元素
	if index == _items.size() - 1:
		_items.pop_back()
		_priorities.pop_back()
		return true

	# 用最后一个元素替换要移除的元素
	_items[index] = _items.pop_back()
	_priorities[index] = _priorities.pop_back()
	
	# 调整堆结构
	_sift_up(index)
	_sift_down(index)
	
	return true

func _find_item_index(item):
	for i in range(_items.size()):
		if _items[i] == item:
			return i
	return -1

func _sift_up(index):
	while index > 0:
		var parent = (index - 1) / 2
		if _priorities[index] >= _priorities[parent]:
			break
		_swap(index, parent)
		index = parent

func _sift_down(index):
	var size = _items.size()
	while index < size:
		var left = 2 * index + 1
		var right = 2 * index + 2
		var smallest = index

		if left < size and _priorities[left] < _priorities[smallest]:
			smallest = left
		if right < size and _priorities[right] < _priorities[smallest]:
			smallest = right

		if smallest == index:
			break

		_swap(index, smallest)
		index = smallest

func _swap(i, j):
	var temp_item = _items[i]
	_items[i] = _items[j]
	_items[j] = temp_item

	var temp_priority = _priorities[i]
	_priorities[i] = _priorities[j]
	_priorities[j] = temp_priority
