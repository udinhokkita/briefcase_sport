import 'package:flutter/material.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final schedules = [
      {
        'title': 'Football Match',
        'date': '18 March 2026',
        'time': '8:00 AM',
      },
      {
        'title': 'Badminton Tournament',
        'date': '20 March 2026',
        'time': '10:00 AM',
      },
      {
        'title': 'Training Session',
        'date': '22 March 2026',
        'time': '5:00 PM',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: const Color(0xFF0B1220),
      ),

      // 🔥 BACKGROUND MATCH TO TOURNAMENT
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B1220),
              Color(0xFF0F172A),
              Color(0xFF111827),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Column(
          children: [
            // 🔥 HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF111827),
                      Color(0xFF0F172A),
                    ],
                  ),
                  border: Border.all(color: Color(0xFF1F2937)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF22C55E).withOpacity(0.14),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Schedule',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage your upcoming matches and events.',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔥 LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 100),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final item = schedules[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1F2937)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color:
                            const Color(0xFF22C55E).withOpacity(0.14),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // TEXT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item['date']} • ${item['time']}',
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}