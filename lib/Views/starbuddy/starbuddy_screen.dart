import 'package:flutter/material.dart';
import '../widgets/chatbot_fab.dart';
import '../widgets/color_codes.dart';

class StarbuddyScreen extends StatefulWidget {
  const StarbuddyScreen({super.key});

  @override
  State<StarbuddyScreen> createState() => _StarbuddyScreenState();
}

class _StarbuddyScreenState extends State<StarbuddyScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _showSuggestions = true;

  final List<Map<String, dynamic>> _suggestions = [
    {'label': 'Career', 'icon': Icons.work_outline},
    {'label': 'Jobs', 'icon': Icons.description_outlined},
    {'label': 'Course', 'icon': Icons.menu_book_outlined},
    {'label': 'Titles', 'icon': Icons.school_outlined},
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _showSuggestions = false;
      _controller.clear();
    });
    // TODO: connect to AI backend
  }

  @override
  void initState() {
    super.initState();
    chatbotFabVisible.value = false;
  }

  @override
  void dispose() {
    chatbotFabVisible.value = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar + Get Pro
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/starbuddy_avatar.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red.shade400),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Get Pro ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.red.shade400,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Right icons
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_outlined, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chat area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 20),

                  // Bot message
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'What can I help you with ?',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/starbuddy_avatar.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // User messages
                  ..._messages.map(
                    (msg) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade300,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                msg['text']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Suggestion chips
                  if (_showSuggestions) ...[
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: _suggestions.map((s) {
                        return GestureDetector(
                          onTap: () => _sendMessage(s['label']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  s['icon'] as IconData,
                                  size: 18,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  s['label'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom input bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                        color: AppColors.background,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask Starbuddy',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const Icon(
                    Icons.mic_none_outlined,
                    color: AppColors.background,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_controller.text),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: AppColors.primaryDark,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
