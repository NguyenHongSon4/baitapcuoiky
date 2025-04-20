import 'package:flutter/material.dart';
import 'dart:io';
import 'package:baitapcuoiky/taskManager/model/Task.dart';
import 'package:baitapcuoiky/taskManager/model/User.dart';
import 'package:baitapcuoiky/taskManager/db/TaskDatabase.dart';
import 'package:baitapcuoiky/taskManager/view/TaskFormScreen.dart';
import 'package:baitapcuoiky/main.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final User currentUser;

  const TaskDetailScreen({super.key, required this.task, required this.currentUser});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    // In ra giá trị của _task.attachments để kiểm tra
    print('Attachments: ${_task.attachments}');
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
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
      );
    }
  }

  bool _isImageFile(String path) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];
    final isImage = imageExtensions.any((ext) => path.toLowerCase().endsWith(ext));
    print('Checking path: $path, isImage: $isImage'); // In ra để kiểm tra
    return isImage;
  }

  Future<void> _editTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(
          currentUser: widget.currentUser,
          task: _task,
        ),
      ),
    );

    if (result == true) {
      final updatedTask = await TaskDatabase.instance.getTask(_task.id);
      if (updatedTask != null) {
        setState(() {
          _task = updatedTask;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật công việc')),
          );
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeSwitching = ThemeSwitchingWidget.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editTask,
          ),
          IconButton(
            icon: Icon(themeSwitching.isDarkMode ? Icons.brightness_7 : Icons.brightness_4),
            onPressed: themeSwitching.toggleTheme,
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
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Không thể tải hình ảnh');
                      },
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
    );
  }
}