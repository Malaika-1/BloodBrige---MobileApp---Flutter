import 'package:flutter/material.dart';

class HealthGuidelinesPage extends StatelessWidget {
  const HealthGuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> guidelines = [
      {
        "title": "1. Consult Your Doctor",
        "desc": "Always consult your doctor before receiving a blood transfusion to ensure it is safe for you."
      },
      {
        "title": "2. Verify Blood Type",
        "desc": "Make sure the blood type of the donor matches your own to avoid complications."
      },
      {
        "title": "3. Check Blood Safety",
        "desc": "Ensure that the blood has been properly screened for infectious diseases like Hepatitis B, C, HIV, and Malaria."
      },
      {
        "title": "4. Stay Hydrated",
        "desc": "Drink enough water before and after the transfusion to support recovery."
      },
      {
        "title": "5. Rest Properly",
        "desc": "Avoid heavy physical activity after a transfusion to allow your body to recover."
      },
      {
        "title": "6. Monitor Symptoms",
        "desc": "Report any unusual symptoms, such as fever, rash, or difficulty breathing, to a medical professional immediately."
      },
      {
        "title": "7. Follow Medical Advice",
        "desc": "Follow all instructions given by your healthcare provider after receiving blood."
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recipient Safety Guidelines",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
            fontFamily: "Ubuntu",
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 135, 9, 13),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: guidelines.length,
        itemBuilder: (context, index) {
          final item = guidelines[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: const Icon(
                Icons.health_and_safety,
                color: Color.fromARGB(255, 135, 9, 13),
                size: 30,
              ),
              title: Text(
                item['title']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: "Ubuntu",
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  item['desc']!,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
