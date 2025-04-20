import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:baitapcuoiky/taskManager/db/TaskDatabase.dart';
import 'package:baitapcuoiky/taskManager/model/Task.dart';
import 'package:baitapcuoiky/taskManager/model/User.dart';
import 'package:baitapcuoiky/main.dart';

class TaskFormScreen extends StatefulWidget {
  final User currentUser;
  final Task? task;

  const TaskFormScreen({super.key, required this.currentUser, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  TaskStatus _status = TaskStatus.toDo;
  String _priority = 'Trung bình';
  DateTime? _dueDate;
  List<String> _attachments = [];

  // Ánh xạ từ int (priority trong Task) sang String (hiển thị trong Dropdown)
  String _priorityToString(int priority) {
    switch (priority) {
      case 1:
        return 'Cao';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Thấp';
      default:
        return 'Trung bình';
    }
  }

  // Ánh xạ từ String (hiển thị trong Dropdown) sang int (priority trong Task)
  int _stringToPriority(String priority) {
    switch (priority) {
      case 'Cao':
        return 1;
      case 'Trung bình':
        return 2;
      case 'Thấp':
        return 3;
      default:
        return 2;
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _categoryController = TextEditingController(text: widget.task?.category ?? '');
    _status = widget.task?.status ?? TaskStatus.toDo;
    _priority = widget.task != null ? _priorityToString(widget.task!.priority) : 'Trung bình';
    _dueDate = widget.task?.dueDate;
    _attachments = widget.task?.attachments ?? [];
    print('Initial attachments: $_attachments');
  }

  Future<void> _pickDueDate() async {
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

  // Chụp ảnh từ camera
  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _attachments.add(pickedFile.path);
        print('Added camera image: ${pickedFile.path}');
      });
    }
  }

  // Chọn ảnh từ thư viện
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _attachments.add(pickedFile.path);
        print('Added gallery image: ${pickedFile.path}');
      });
    }
  }

  // Chọn tệp tài liệu (Word, PDF)
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx', 'pdf'],
      allowMultiple: true, // Cho phép chọn nhiều tệp
    );

    if (result != null) {
      setState(() {
        _attachments.addAll(result.paths.map((path) => path!).toList());
        print('Added documents: ${result.paths}');
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        status: _status,
        priority: _stringToPriority(_priority),
        dueDate: _dueDate,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        assignedTo: widget.currentUser.id,
        createdBy: widget.currentUser.id,
        category: _categoryController.text.isEmpty ? null : _categoryController.text,
        attachments: _attachments.isEmpty ? null : _attachments,
        completed: widget.task?.completed ?? false,
      );

      try {
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeSwitching = ThemeSwitchingWidget.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Tạo Công việc' : 'Chỉnh sửa Công việc'),
        actions: [
          IconButton(
            icon: Icon(themeSwitching.isDarkMode ? Icons.brightness_7 : Icons.brightness_4),
            onPressed: themeSwitching.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
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
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(labelText: 'Độ ưu tiên'),
                  items: const [
                    DropdownMenuItem(value: 'Cao', child: Text('Cao')),
                    DropdownMenuItem(value: 'Trung bình', child: Text('Trung bình')),
                    DropdownMenuItem(value: 'Thấp', child: Text('Thấp')),
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
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Danh mục (tùy chọn)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hạn hoàn thành: ${_dueDate != null ? _dueDate.toString() : 'Chưa chọn'}',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _pickDueDate,
                      child: const Text('Chọn ngày'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Tệp đính kèm:'),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'camera') {
                          _pickImageFromCamera();
                        } else if (value == 'gallery') {
                          _pickImageFromGallery();
                        } else if (value == 'document') {
                          _pickDocument();
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'camera',
                          child: Text('Chụp ảnh từ camera'),
                        ),
                        const PopupMenuItem(
                          value: 'gallery',
                          child: Text('Chọn ảnh từ thư viện'),
                        ),
                        const PopupMenuItem(
                          value: 'document',
                          child: Text('Chọn tài liệu (Word, PDF)'),
                        ),
                      ],
                      child: ElevatedButton(
                        onPressed: null, // PopupMenuButton sẽ xử lý sự kiện
                        child: const Text('Thêm tệp'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _attachments.isNotEmpty
                    ? Wrap(
                  children: _attachments
                      .map((attachment) => Chip(
                    label: Text(attachment.split('/').last),
                    onDeleted: () {
                      setState(() {
                        _attachments.remove(attachment);
                      });
                    },
                  ))
                      .toList(),
                )
                    : const Text('Chưa có tệp đính kèm'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveTask,
                  child: const Text('Lưu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}