import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_budget_app/utils/appvalidator.dart';
import 'package:flutter_budget_app/widgets/category_dropdown.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddTransactionForm extends StatefulWidget {
  const AddTransactionForm({super.key});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  var type = "cr";
  var category = "Others";
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var isLoader = false;
  var appValidator = AppValidator();
  var amountEditController = TextEditingController();
  var titleEditController = TextEditingController();
  var uid = Uuid();
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoader = true;
      });
      final user = FirebaseAuth.instance.currentUser;
      int timestamp = DateTime.now().microsecondsSinceEpoch;
      var amount = int.parse(amountEditController.text);
      DateTime date = DateTime.now();
      var id = uid.v4();
      String monthly = DateFormat('MMM y').format(date);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      int remainingAmount = userDoc['remainingAmount'];
      int totalCredit = userDoc['totalCredit'];
      int totalDebit = userDoc['totalDebit'];

      if (type == 'crédit') {
        remainingAmount += amount;
        totalCredit += amount;
      } else {
        remainingAmount -= amount;
        totalCredit -= amount;
      }
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        "remainingAmount" : remainingAmount,
        "totalCredit": totalCredit,
        "totalDebit": totalDebit,
        "updatedAt": timestamp,
      });
      var data = {
         "id" : id,
         "title": titleEditController.text,
         "amount": amount,
         "type": type,
         "timestamp": timestamp,
         "totalCredit": totalCredit,
         "totalDebit" : totalDebit,
         "remainingAmount" : remainingAmount,
         "monthYear" : monthyear,
         "category" : category,
        };
      // await authService.login(data, context);
      setState(() {
        isLoader = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: titleEditController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: appValidator.isEmptyCheck,
            decoration: InputDecoration(labelText: 'Title'),
          ),
          TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: appValidator.isEmptyCheck,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Amount'),
          ),
          CategoryDropDown(
              cattype: category,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    category = value;
                  });
                }
              }),
          DropdownButtonFormField(
              value: 'crédit',
              items: [
                DropdownMenuItem(
                  child: Text('Crédit'),
                  value: 'crédit',
                ),
                DropdownMenuItem(
                  child: Text('Débit'),
                  value: 'Débit',
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    type = value;
                  });
                }
              }),
          SizedBox(
            height: 16,
          ),
          ElevatedButton(
              onPressed: () {
                if (isLoader == false) {
                  _submitForm();
                }
              },
              child: isLoader
                  ? Center(child: CircularProgressIndicator())
                  : Text("Add Transaction"))
        ]),
      ),
    );
  }
}
