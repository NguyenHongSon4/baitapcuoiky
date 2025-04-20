import 'package:flutter/material.dart';
import 'dart:io';
import '../model/Task.dart';
import '../db/TaskDatabase.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _updateStatus(TaskStatus newStatus) async {
    try {
      final updatedTask = _task.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await TaskDatabase.instance.updateTask(updatedTask);
      setState(() {
        _task = updatedTask;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
      );
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  bool _isImageFile(String path) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];
    return imageExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode
          ? ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.blue[300],
          ),
        ),
      )
          : ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết Công việc'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.brightness_7 : Icons.brightness_4),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _task.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text('Mô tả: ${_task.description}'),
                const SizedBox(height: 8),
                Text('Trạng thái: ${_task.status.toString().split('.').last}'),
                const SizedBox(height: 8),
                Text('Độ ưu tiên: ${_task.priority}'),
                const SizedBox(height: 8),
                Text(
                    'Hạn hoàn thành: ${_task.dueDate != null ? _task.dueDate.toString() : 'Không có'}'),
                const SizedBox(height: 8),
                Text('Thời gian tạo: ${_task.createdAt}'),
                const SizedBox(height: 8),
                Text('Cập nhật gần nhất: ${_task.updatedAt}'),
                const SizedBox(height: 8),
                Text('Người được giao: ${_task.assignedTo ?? 'Không có'}'),
                const SizedBox(height: 8),
                Text('Người tạo: ${_task.createdBy}'),
                const SizedBox(height: 8),
                Text('Danh mục: ${_task.category ?? 'Không có'}'),
                const SizedBox(height: 8),
                Text('Hoàn thành: ${_task.completed ? 'Có' : 'Không'}'),
                const SizedBox(height: 16),
                const Text('Tệp đính kèm:', style: TextStyle(fontWeight: FontWeight.bold)),
                _task.attachments != null && _task.attachments!.isNotEmpty
                    ? Column(
                  children: _task.attachments!
                      .map((attachment) => _isImageFile(attachment)
                      ? Column(
                    children: [
                      Image.file(
                        File(attachment),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 8),
                    ],
                  )
                      : ListTile(
                    title: Text(attachment),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mở tệp: $attachment')),
                      );
                    },
                  ))
                      .toList(),
                )
                    : const Text('Không có tệp đính kèm'),
                const SizedBox(height: 16),
                const Text('Cập nhật trạng thái:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<TaskStatus>(
                  value: _task.status,
                  isExpanded: true,
                  items: TaskStatus.values
                      .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.toString().split('.').last),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateStatus(value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}