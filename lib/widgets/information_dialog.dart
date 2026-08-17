import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
// import 'package:restart_app/restart_app.dart';

class InformationDialog extends StatefulWidget {
  final String? title, description;
  const InformationDialog({super.key, this.title, this.description});

  @override
  State<InformationDialog> createState() => _InformationDialogState();
}

class _InformationDialogState extends State<InformationDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Text(
                  widget.title.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                Text(
                  widget.description.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                SizedBox(
                  width: 202,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Phoenix.rebirth(context);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
