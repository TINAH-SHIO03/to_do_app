import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/db_helper.dart';
import '/models/task.dart';
import '/providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  List<Task> _tasks = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
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
      debugPrint('Current user loaded: $_currentUser');
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in. Please log in.')),
        );
      }
    });
    if (_currentUser != null) {
      _loadTasks();
    }
  }

  void _loadTasks() async {
    if (_currentUser == null) {
      debugPrint('Cannot load tasks: currentUser is null');
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
      debugPrint(
        'Fetching tasks for user: $_currentUser, date: $formattedDate',
      );

      final allTasksMaps = await DBHelper.instance.getTasks(_currentUser!);
      final allTasks = allTasksMaps.map((map) => Task.fromMap(map)).toList();
      final newTasks = allTasks
          .where((task) => task.date == formattedDate)
          .toList();

      if (!mounted) return;

      setState(() {
        final oldTasks = _tasks;
        _tasks = newTasks;

        debugPrint(
          'Tasks loaded: ${newTasks.length} tasks found for date $formattedDate',
        );

        if (_listKey.currentState != null) {
          final oldLength = oldTasks.length;
          final newLength = _tasks.length;

          if (newLength < oldLength) {
            for (int i = oldLength - 1; i >= newLength; i--) {
              _listKey.currentState!.removeItem(
                i,
                (context, animation) => _buildTaskItem(oldTasks[i], animation),
                duration: const Duration(milliseconds: 300),
              );
            }
          }

          for (int i = oldLength; i < newLength; i++) {
            _listKey.currentState!.insertItem(
              i,
              duration: const Duration(milliseconds: 300),
            );
          }
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading tasks: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load tasks: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteTask(int id, int index) async {
    try {
      setState(() {
        _isLoading = true;
      });
      await DBHelper.instance.deleteTask(id, _currentUser ?? '');
      if (!mounted) return;
      final removedTask = _tasks.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildTaskItem(removedTask, animation),
        duration: const Duration(milliseconds: 300),
      );
    } catch (e, stackTrace) {
      debugPrint('Error deleting task: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete task: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showTaskDetails(Task task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? Colors.grey[900]
            : Theme.of(context).dialogTheme.backgroundColor,
        title: Text(
          task.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Note: ${task.note}',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            Text(
              'Date: ${task.date}',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            Text(
              'Start Time: ${task.startTime}',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            Text(
              'End Time: ${task.endTime}',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        color: Color(int.parse(task.color)),
        child: ListTile(
          title: Text(task.title),
          subtitle: Text('${task.date} ${task.startTime} - ${task.endTime}'),
          onTap: () => _showTaskDetails(task),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              final index = _tasks.indexOf(task);
              _deleteTask(task.id!, index);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(themeProvider.isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => themeProvider.toggleTheme(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                elevation: 0,
              ),
              onPressed: () {
                if (_currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please log in to add tasks')),
                  );
                  return;
                }
                setState(() {
                  _isLoading = true;
                });
                Navigator.pushNamed(context, '/add_task').then((result) {
                  if (result == true) {
                    _loadTasks();
                  }
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _selectedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                      });
                      _loadTasks();
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: TextStyle(
                        color: themeProvider.isDark
                            ? Colors.white
                            : Colors.black,
                      ),
                      weekendTextStyle: TextStyle(
                        color: themeProvider.isDark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                      outsideTextStyle: TextStyle(
                        color: themeProvider.isDark
                            ? Colors.white54
                            : Colors.black54,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).primaryColor,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _tasks.isEmpty
                        ? const Center(child: Text('No tasks for this day'))
                        : AnimatedList(
                            key: _listKey,
                            initialItemCount: _tasks.length,
                            itemBuilder: (context, index, animation) {
                              if (index >= _tasks.length) {
                                return const SizedBox.shrink();
                              }
                              return _buildTaskItem(_tasks[index], animation);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
