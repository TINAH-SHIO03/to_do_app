import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/db_helper.dart';
import '/models/task.dart';
import '/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  AddTaskScreenState createState() => AddTaskScreenState();
}

class AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _color = '0xFF2196F3';
  String? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUser = prefs.getString('current_user');
      debugPrint('AddTaskScreen: Current user loaded: $_currentUser');
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in. Please log in.')),
        );
      }
    });
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          _startTimeController.text = picked.format(context);
        } else {
          _endTime = picked;
          _endTimeController.text = picked.format(context);
        }
      });
    }
  }

  void _createTask() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in. Please log in.')),
      );
      return;
    }
    if (_titleController.text.isEmpty ||
        _date == null ||
        _startTime == null ||
        _endTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final task = Task(
        title: _titleController.text,
        note: _noteController.text,
        date: DateFormat('yyyy-MM-dd').format(_date!),
        startTime: DateFormat(
          'HH:mm',
        ).format(DateTime(0, 0, 0, _startTime!.hour, _startTime!.minute)),
        endTime: DateFormat(
          'HH:mm',
        ).format(DateTime(0, 0, 0, _endTime!.hour, _endTime!.minute)),
        color: _color,
        userName: _currentUser,
      );

      final id = await DBHelper.instance.insertTask(
        task.toMap(),
        _currentUser!,
      );
      debugPrint(
        'Task saved with ID: $id, Title: ${task.title}, Date: ${task.date}, User: $_currentUser',
      );

      final taskWithId = Task(
        id: id,
        title: task.title,
        note: task.note,
        date: task.date,
        startTime: task.startTime,
        endTime: task.endTime,
        color: task.color,
        userName: task.userName,
      );

      await NotificationService.instance.scheduleTaskNotification(
        task: taskWithId,
        notificationId: id,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint('Error creating task: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create task: $e')));
      Navigator.pop(context, false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Task')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter title';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () => _pickTime(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () => _pickTime(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _color,
                  items: const [
                    DropdownMenuItem(value: '0xFF2196F3', child: Text('Blue')),
                    DropdownMenuItem(
                      value: '0xFFE040FB',
                      child: Text('Pink Accent'),
                    ),
                    DropdownMenuItem(
                      value: '0xFF7C4DFF',
                      child: Text('Purple Accent'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _color = value!),
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Create Task',
                  onPressed: _createTask,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }
}
