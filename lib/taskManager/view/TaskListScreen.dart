import 'package:flutter/material.dart';
import '../db/TaskDatabase.dart';
import '../model/Task.dart';
import '../model/User.dart';
import 'TaskDetailScreen.dart';
import 'TaskFormScreen.dart';
import 'TaskItem.dart';
import 'package:baitapcuoiky/main.dart';  // Import main.dart để sử dụng ThemeSwitchingWidget

class TaskListScreen extends StatefulWidget {
  final User currentUser;

  const TaskListScreen({super.key, required this.currentUser});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchController.addListener(_filterTasks);
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await TaskDatabase.instance.getAllTasks();
      setState(() {
        _tasks = tasks;
        _filteredTasks = tasks;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải công việc: $e')),
      );
    }
  }

  void _filterTasks() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      _filteredTasks = _tasks.where((task) {
        final matchesKeyword = task.title.toLowerCase().contains(keyword) ||
            task.description.toLowerCase().contains(keyword);
        final matchesStatus = _selectedStatus == null ||
            task.status.toString().split('.').last == _selectedStatus;
        final matchesCategory =
            _selectedCategory == null || task.category == _selectedCategory;
        return matchesKeyword && matchesStatus && matchesCategory;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedCategory = null;
      _filteredTasks = _tasks;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy ThemeSwitchingWidget để truy cập isDarkMode và toggleTheme
    final themeSwitching = ThemeSwitchingWidget.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Công việc'),
        actions: [
          IconButton(
            icon: Icon(themeSwitching.isDarkMode ? Icons.brightness_7 : Icons.brightness_4),
            onPressed: themeSwitching.toggleTheme, // Sử dụng toggleTheme từ ThemeSwitchingWidget
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFilters,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm công việc',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: const Text('Trạng thái'),
                    value: _selectedStatus,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tất cả trạng thái'),
                      ),
                      ...TaskStatus.values.map((status) => DropdownMenuItem(
                        value: status.toString().split('.').last,
                        child: Text(status.toString().split('.').last),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                        _filterTasks();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    hint: const Text('Danh mục'),
                    value: _selectedCategory,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tất cả danh mục'),
                      ),
                      ..._tasks
                          .map((task) => task.category)
                          .where((category) => category != null)
                          .toSet()
                          .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category!),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _filterTasks();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredTasks.isEmpty
                ? const Center(child: Text('Không có công việc nào'))
                : ListView.builder(
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                return TaskItem(
                  task: _filteredTasks[index],
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: Text(
                            'Bạn có chắc chắn muốn xóa công việc "${_filteredTasks[index].title}" không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await TaskDatabase.instance
                            .deleteTask(_filteredTasks[index].id);
                        _loadTasks();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Đã xóa công việc')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                Text('Lỗi khi xóa công việc: $e')),
                          );
                        }
                      }
                    }
                  },
                  onToggleComplete: () async {
                    final task = _filteredTasks[index];
                    final updatedTask = task.copyWith(
                      completed: !task.completed,
                      updatedAt: DateTime.now(),
                    );
                    await TaskDatabase.instance.updateTask(updatedTask);
                    _loadTasks();
                  },
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(
                          task: _filteredTasks[index],
                          currentUser: widget.currentUser,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadTasks();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskFormScreen(currentUser: widget.currentUser),
            ),
          );
          if (result == true) {
            _loadTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}