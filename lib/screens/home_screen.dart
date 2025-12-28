import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/screens/add_tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Inisialisasi list kosong, data akan diisi oleh loadTasks()
  List<Task> tasks = [];

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskJson = tasks
        .map((task) => {"title": task.title, "isDone": task.isDone})
        .toList();
    prefs.setString("tasks", jsonEncode(taskJson));
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskString = prefs.getString("tasks");
    if (taskString != null) {
      final List<dynamic> taskJson = jsonDecode(taskString);
      setState(() {
        tasks = taskJson
            .map(
              (json) =>
                  Task(title: json["title"], isDone: json["isDone"] ?? false),
            )
            .toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Task"),
        actions: [
          IconButton(
            onPressed: () async {
              final newTaskTitle = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (context) => const AddTasksScreen()),
              );

              if (newTaskTitle != null && newTaskTitle.isNotEmpty) {
                setState(() {
                  tasks.add(Task(title: newTaskTitle));
                });
                saveTasks();
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(
              child: Text(
                "Belum Ada Task Saat Ini.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Dismissible(
                  // Gunakan UniqueKey agar tidak terjadi error saat menghapus item
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      tasks.removeAt(index);
                    });
                    saveTasks();
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      // --- BAGIAN PERUBAHAN: FUNGSI CENTANG ---
                      leading: IconButton(
                        icon: Icon(
                          task.isDone
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: task.isDone ? Colors.green : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            // Membalikkan status isDone (true jadi false, vice versa)
                            task.isDone = !task.isDone;
                          });
                          saveTasks(); // Simpan perubahan status ke storage
                        },
                      ),
                      // ---------------------------------------
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isDone ? Colors.grey : Colors.black,
                        ),
                      ),
                      onTap: () async {
                        final editedTaskTitle = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddTasksScreen(existingTitle: task.title),
                          ),
                        );
                        if (editedTaskTitle != null &&
                            editedTaskTitle.isNotEmpty) {
                          setState(() {
                            tasks[index].title = editedTaskTitle;
                          });
                          saveTasks();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
