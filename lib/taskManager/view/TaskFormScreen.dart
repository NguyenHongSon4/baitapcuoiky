import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../db/TaskDatabase.dart';
import '../db/UserDatabase.dart';
import '../model/Task.dart';
import '../model/User.dart';
import 'dart:io';

class TaskFormScreen extends StatefulWidget {
  final User currentUser;
  final Task? task;

  const TaskFormScreen({super.key, required this.currentUser, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  TaskStatus _status = TaskStatus.toDo;
  int _priority = 1;
  DateTime? _dueDate;
  String? _assignedTo;
  List<String> _attachments = [];
  bool _completed = false;
  List<User> _users = [];
  bool _isDarkMode = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _status = widget.task!.status;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
      _assignedTo = widget.task!.assignedTo;
      _categoryController.text = widget.task!.category ?? '';
      _attachments = widget.task!.attachments ?? [];
      _completed = widget.task!.completed;
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await UserDatabase.instance.getAllUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách người dùng: $e')),
      );
    }
  }

  Future<void> _selectDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _attachments.add(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachments.add(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn tệp: $e')),
      );
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        final task = Task(
          id: widget.task?.id ?? const Uuid().v4(),
          title: _titleController.text,
          description: _descriptionController.text,
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          createdAt: widget.task?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          assignedTo: _assignedTo,
          createdBy: widget.currentUser.id,
          category: _categoryController.text.isEmpty ? null : _categoryController.text,
          attachments: _attachments.isEmpty ? null : _attachments,
          completed: _completed,
        );

        if (widget.task == null) {
          await TaskDatabase.instance.insertTask(task);
        } else {
          await TaskDatabase.instance.updateTask(task);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu công việc: $e')),
        );
      }
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
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
          title: Text(widget.task == null ? 'Thêm Công việc' : 'Sửa Công việc'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.brightness_7 : Icons.brightness_4),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mô tả';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskStatus>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Trạng thái'),
                    items: TaskStatus.values
                        .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.toString().split('.').last),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Độ ưu tiên'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Thấp')),
                      DropdownMenuItem(value: 2, child: Text('Trung bình')),
                      DropdownMenuItem(value: 3, child: Text('Cao')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _priority = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hạn hoàn thành: ${_dueDate != null ? DateFormat('dd/MM/yyyy').format(_dueDate!) : 'Chưa chọn'}',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _selectDueDate,
                        child: const Text('Chọn ngày'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _assignedTo,
                    decoration: const InputDecoration(labelText: 'Người được giao'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Không có')),
                      ..._users.map((user) => DropdownMenuItem(
                        value: user.id,
                        child: Text(user.username),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _assignedTo = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Danh mục (tùy chọn)'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tệp đính kèm:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _pickImage(ImageSource.camera),
                        child: const Text('Chụp ảnh'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        child: const Text('Chọn ảnh'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _pickFile,
                        child: const Text('Chọn tệp'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _attachments.isNotEmpty
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Danh sách tệp đính kèm:'),
                      ..._attachments
                          .asMap()
                          .entries
                          .map((entry) => Row(
                        children: [
                          Expanded(child: Text(entry.value)),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _attachments.removeAt(entry.key);
                              });
                            },
                          ),
                        ],
                      )),
                    ],
                  )
                      : const Text('Không có tệp đính kèm'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Hoàn thành:'),
                      Checkbox(
                        value: _completed,
                        onChanged: (value) {
                          setState(() {
                            _completed = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      child: Text(widget.task == null ? 'Thêm' : 'Cập nhật'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}