import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class Task {
  String id;
  String name;
  bool isCompleted;

  Task(this.name, {this.isCompleted = false, this.id = ''});
}

class TaskList with ChangeNotifier {
  List<Task> _tasks = [];
  final String userId;
  final DatabaseReference _tasksRef;

  TaskList(this.userId)
      : _tasksRef = FirebaseDatabase.instance.ref('users').child(userId).child('tasks');

  List<Task> get tasks => _tasks;

  Future<void> fetchTasks() async {
    print('Fetching tasks for user: $userId');
    final snapshot = await _tasksRef.once();
    _tasks = snapshot.snapshot.children.map((task) {
      print('Fetched task: ${task.child('name').value}');
      return Task(
        task.child('name').value as String,
        isCompleted: task.child('isCompleted').value as bool,
        id: task.key ?? '',
      );
    }).toList();
    print('Fetched ${_tasks.length} tasks');
    notifyListeners();
  }

  Future<void> addTask(String name) async {
    final newTask = Task(name);
    final taskRef = await _tasksRef.push();
    newTask.id = taskRef.key ?? '';
    await taskRef.set({
      'name': newTask.name,
      'isCompleted': newTask.isCompleted,
    });
    _tasks.add(newTask);
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(int index) async {
    final task = _tasks[index];
    task.isCompleted = !task.isCompleted;
    await _tasksRef.child(task.id).update({
      'isCompleted': task.isCompleted,
    });
    notifyListeners();
  }

  Future<void> deleteTask(int index) async {
    final task = _tasks[index];
    await _tasksRef.child(task.id).remove();
    _tasks.removeAt(index);
    notifyListeners();
  }
}
