import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class Student {
  String documento;
  String nombres;
  int edad;

  Student({
    required this.documento,
    required this.nombres,
    required this.edad,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: StudentList(),
    );
  }
}

class StudentList extends StatefulWidget {
  const StudentList({Key? key}) : super(key: key);

  @override
  _StudentListState createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  final CollectionReference studentsCollection =
      FirebaseFirestore.instance.collection('students');

  late List<Student> students;

  @override
  void initState() {
    super.initState();
    students = [];
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final querySnapshot = await studentsCollection.get();
    final List<Student> fetchedStudents = querySnapshot.docs
        .map((doc) => Student(
              documento: doc['documento'] as String,
              nombres: doc['nombres'] as String,
              edad: doc['edad'] as int,
            ))
        .toList();

    setState(() {
      students = fetchedStudents;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiantes'),
      ),
      body: StudentListView(
        students: students,
        onEdit: _navigateToStudentForm,
        onDelete: _deleteStudent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToStudentForm(null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToStudentForm(Student? student) async {
    final newStudent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentForm(
          student: student,
          existingDocuments: students.map((s) => s.documento).toList(),
          onSave: _saveStudent,
        ),
      ),
    );

    if (newStudent != null) {
      if (student == null) {
        await studentsCollection.add({
          'documento': newStudent.documento,
          'nombres': newStudent.nombres,
          'edad': newStudent.edad,
        });
      } else {
        // Implementar la actualización del estudiante si es necesario
      }

      fetchStudents(); // Actualizar la lista después de la operación en Firestore
    }
  }

  void _deleteStudent(Student student) async {
    await studentsCollection
        .where('documento', isEqualTo: student.documento)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.delete();
      });
    });

    fetchStudents(); // Actualizar la lista después de la operación en Firestore
  }

  Future<void> _saveStudent(Student student) async {
    // Implementar la lógica para guardar o actualizar el estudiante si es necesario
  }
}

class StudentListView extends StatelessWidget {
  final List<Student> students;
  final void Function(Student student) onEdit;
  final void Function(Student student) onDelete;

  const StudentListView({
    Key? key,
    required this.students,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return ListTile(
          title: Text(student.nombres),
          subtitle:
              Text('Documento: ${student.documento} - Edad: ${student.edad}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  onEdit(student);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  onDelete(student);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class StudentForm extends StatefulWidget {
  final Student? student;
  final List<String> existingDocuments;
  final void Function(Student student) onSave;

  const StudentForm({
    Key? key,
    this.student,
    required this.existingDocuments,
    required this.onSave,
  }) : super(key: key);

  @override
  _StudentFormState createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final TextEditingController documentoController = TextEditingController();
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController edadController = TextEditingController();

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      documentoController.text = widget.student!.documento;
      nombresController.text = widget.student!.nombres;
      edadController.text = widget.student!.edad.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.student == null ? 'Agregar Estudiante' : 'Editar Estudiante',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            TextField(
              controller: documentoController,
              decoration:
                  const InputDecoration(labelText: 'Documento de Identidad'),
              keyboardType: TextInputType.number, // Solo permite números
            ),
            TextField(
              controller: nombresController,
              decoration: const InputDecoration(labelText: 'Nombres'),
            ),
            TextField(
              controller: edadController,
              decoration: const InputDecoration(labelText: 'Edad'),
              keyboardType: TextInputType.number, // Solo permite números
            ),
            ElevatedButton(
              onPressed: () {
                final newDocumento = documentoController.text;
                if (widget.existingDocuments.contains(newDocumento)) {
                  setState(() {
                    errorMessage = 'Documento ya existente';
                  });
                } else {
                  setState(() {
                    errorMessage = null;
                  });

                  final newStudent = Student(
                    documento: newDocumento,
                    nombres: nombresController.text,
                    edad: int.parse(edadController.text),
                  );
                  widget.onSave(newStudent);
                  Navigator.pop(context, newStudent);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
