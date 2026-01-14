import 'package:flutter/material.dart';

class HealthGuidelinesPage extends StatelessWidget {
  const HealthGuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> guidelines = [
      {
        "title": "1. Stay Hydrated",
        "desc": "Drink plenty of water before and after donating blood to stay hydrated and recover quickly."
      },
      {
        "title": "2. Eat a Healthy Meal",
        "desc": "Avoid fatty foods and eat a balanced meal before donating to maintain your blood sugar levels."
      },
      {
        "title": "3. Get Enough Sleep",
        "desc": "Make sure you’ve had at least 7–8 hours of sleep the night before donation."
      },
      {
        "title": "4. Avoid Alcohol & Smoking",
        "desc": "Do not consume alcohol or smoke 24 hours before or after donating blood."
      },
      {
        "title": "5. Rest After Donation",
        "desc": "Avoid heavy lifting or strenuous activity for 24 hours after donating."
      },
      {
        "title": "6. Eat Iron-Rich Foods",
        "desc": "Include foods like spinach, beans, and lean meats to restore your iron levels."
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Health & Safety Guidelines",
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
              leading: const Icon(Icons.health_and_safety,
                  color: Color.fromARGB(255, 135, 9, 13), size: 30),
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
