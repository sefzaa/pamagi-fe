import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/home/logic/home_state.dart';
import 'package:pamagi/features/home/presentation/word_list_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class GroupListScreen extends StatefulWidget {
  final bool isCategory;
  const GroupListScreen({super.key, required this.isCategory});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  late bool isCategoryTab;

  @override
  void initState() {
    super.initState();
    isCategoryTab = widget.isCategory;
  }

  IconData _getIcon(String? iconName) {
    final Map<String, IconData> iconMap = {
      'folder': LucideIcons.folder, 'book': LucideIcons.book, 'briefcase': LucideIcons.briefcase,
      'coffee': LucideIcons.coffee, 'globe': LucideIcons.globe, 'heart': LucideIcons.heart,
      'music': LucideIcons.music, 'shopping_cart': LucideIcons.shopping_cart, 'camera': LucideIcons.camera,
      'utensils': LucideIcons.utensils, 'car': LucideIcons.car, 'plane': LucideIcons.plane,
    };
    return iconMap[iconName?.toLowerCase()] ?? LucideIcons.folder;
  }

  IconData _getPosIcon(String? posName) {
    final Map<String, IconData> posMap = {
      'NOUN': Icons.category, 'VERB': Icons.directions_run, 'ADJECTIVE': Icons.color_lens,
      'ADVERB': Icons.fast_forward, 'PRONOUN': Icons.person, 'PREPOSITION': Icons.place,
      'CONJUNCTION': Icons.link, 'INTERJECTION': Icons.feedback, 'IDIOM': Icons.forum, 'NONE': Icons.help_outline
    };
    return posMap[posName?.toUpperCase()] ?? Icons.text_snippet;
  }

  void _showCategoryOptions(BuildContext context, Map<String, dynamic> category) {
    if (category['id'] == 'uncategorized') return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Edit Category'),
              onTap: () {
                Navigator.pop(ctx);
                _showCategoryForm(context, category: category);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Category', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteCategory(context, category['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text('This category will be deleted. Words inside it will remain as Uncategorized.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<HomeCubit>().repository.deleteCategory(id);
                if (context.mounted) context.read<HomeCubit>().fetchDashboardData();
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCategoryForm(BuildContext context, {Map<String, dynamic>? category}) {
    final catController = TextEditingController(text: category?['name'] ?? '');
    String selectedIcon = category?['icon'] ?? 'folder';

    // Daftar Icon Lucide persis seperti di halaman tambah kata
    final Map<String, IconData> iconList = {
      'folder': LucideIcons.folder, 'book': LucideIcons.book, 'briefcase': LucideIcons.briefcase, 'coffee': LucideIcons.coffee, 'globe': LucideIcons.globe, 'heart': LucideIcons.heart, 'music': LucideIcons.music, 'shopping_cart': LucideIcons.shopping_cart, 'camera': LucideIcons.camera, 'utensils': LucideIcons.utensils, 'car': LucideIcons.car, 'plane': LucideIcons.plane, 'activity': LucideIcons.activity, 'alarm_clock': LucideIcons.alarm_clock, 'anchor': LucideIcons.anchor, 'apple': LucideIcons.apple, 'archive': LucideIcons.archive, 'award': LucideIcons.award, 'backpack': LucideIcons.backpack, 'battery': LucideIcons.battery, 'bell': LucideIcons.bell, 'cloud': LucideIcons.cloud, 'cpu': LucideIcons.cpu, 'database': LucideIcons.database, 'droplet': LucideIcons.droplet, 'feather': LucideIcons.feather, 'flag': LucideIcons.flag, 'gift': LucideIcons.gift, 'glasses': LucideIcons.glasses, 'headphones': LucideIcons.headphones, 'key': LucideIcons.key, 'laptop': LucideIcons.laptop, 'map': LucideIcons.map, 'mic': LucideIcons.mic, 'moon': LucideIcons.moon, 'pen_tool': LucideIcons.pen_tool, 'printer': LucideIcons.printer, 'radio': LucideIcons.radio, 'scissors': LucideIcons.scissors, 'shield': LucideIcons.shield, 'smartphone': LucideIcons.smartphone, 'speaker': LucideIcons.speaker, 'star': LucideIcons.star, 'sun': LucideIcons.sun, 'target': LucideIcons.target, 'tv': LucideIcons.tv, 'umbrella': LucideIcons.umbrella, 'video': LucideIcons.video, 'watch': LucideIcons.watch, 'wifi': LucideIcons.wifi,
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(category == null ? 'Add Category' : 'Edit Category', style: const TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: catController,
                  decoration: const InputDecoration(
                      hintText: 'Category Name',
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00AA5B)))
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Select Icon:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: iconList.entries.map((entry) {
                    final isSelected = selectedIcon == entry.key;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00AA5B).withOpacity(0.2) : Colors.transparent,
                            border: Border.all(color: isSelected ? const Color(0xFF00AA5B) : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Icon(entry.value, color: isSelected ? const Color(0xFF00AA5B) : Colors.grey),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AA5B)),
              onPressed: () async {
                if (catController.text.isNotEmpty) {
                  Navigator.pop(ctx);
                  try {
                    if (category == null) {
                      await context.read<HomeCubit>().repository.addCategory(catController.text, selectedIcon);
                    } else {
                      await context.read<HomeCubit>().repository.updateCategory(category['id'], catController.text, selectedIcon);
                    }
                    if (context.mounted) context.read<HomeCubit>().fetchDashboardData();
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Groups & Categories', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF00AA5B)),
        elevation: 0,
      ),
      floatingActionButton: isCategoryTab
          ? FloatingActionButton(
        backgroundColor: const Color(0xFF00AA5B),
        onPressed: () => _showCategoryForm(context),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
      body: Column(
        children: [
          // TAB SWITCHER (Categories | Word Types)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => isCategoryTab = true),
                  child: Column(
                    children: [
                      Text('Categories', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isCategoryTab ? const Color(0xFF00AA5B) : Colors.grey)),
                      const SizedBox(height: 6),
                      Container(height: 3, width: 80, color: isCategoryTab ? const Color(0xFF00AA5B) : Colors.transparent),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => setState(() => isCategoryTab = false),
                  child: Column(
                    children: [
                      Text('Word Types', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: !isCategoryTab ? const Color(0xFF00AA5B) : Colors.grey)),
                      const SizedBox(height: 6),
                      Container(height: 3, width: 80, color: !isCategoryTab ? const Color(0xFF00AA5B) : Colors.transparent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // LIST ITEMS
          Expanded(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (state is HomeLoaded) {
                  final items = isCategoryTab ? state.categories : state.wordTypes;

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final title = isCategoryTab ? item['name'] : item['part_of_speech'];
                      final count = item['count'] ?? 0;
                      final icon = isCategoryTab ? _getIcon(item['icon']) : _getPosIcon(item['part_of_speech']);

                      return InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => WordListScreen(
                            repository: context.read<HomeCubit>().repository,
                            title: title,
                            categoryId: isCategoryTab ? item['id'] : null,
                            pos: !isCategoryTab ? item['part_of_speech'] : null,
                          )));
                        },
                        onLongPress: () {
                          if (isCategoryTab) _showCategoryOptions(context, item);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                                child: Icon(icon, color: const Color(0xFF00AA5B)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('$count words', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)));
              },
            ),
          ),
        ],
      ),
    );
  }
}