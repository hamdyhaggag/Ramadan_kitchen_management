import 'package:flutter/material.dart';

class ManageCasesScreen extends StatefulWidget {
  const ManageCasesScreen({super.key});

  @override
  ManageCasesScreenState createState() => ManageCasesScreenState();
}

class ManageCasesScreenState extends State<ManageCasesScreen> {
  List<Map<String, dynamic>> cases = [
    {'name': 'Family A', 'members': 5, 'bagStatus': 'Not Distributed'},
    {'name': 'Family B', 'members': 3, 'bagStatus': 'Distributed'},
  ];

  void addCase(String name, int members) {
    setState(() {
      cases.add(
          {'name': name, 'members': members, 'bagStatus': 'Not Distributed'});
    });
  }

  void updateCase(int index, String name, int members, String bagStatus) {
    setState(() {
      cases[index] = {'name': name, 'members': members, 'bagStatus': bagStatus};
    });
  }

  void deleteCase(int index) {
    setState(() {
      cases.removeAt(index);
    });
  }

  void generateReport() {
    // Add logic to create and share PDF report
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Cases')),
      body: ListView.builder(
        itemCount: cases.length,
        itemBuilder: (context, index) {
          final caseItem = cases[index];
          return ListTile(
            title: Text('${caseItem['name']} (${caseItem['members']} members)'),
            subtitle: Text('Bag Status: ${caseItem['bagStatus']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    // Edit case logic
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deleteCase(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add case logic
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
