import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/browser_model.dart';

class CssManagerScreen extends StatelessWidget {
  const CssManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom CSS Manager'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<BrowserModel>(
        builder: (context, model, child) {
          final rules = model.customCssRules;
          if (rules.isEmpty) {
            return const Center(child: Text("No custom CSS rules defined."));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final domain = rules.keys.elementAt(index);
              final css = rules[domain]!;
              return ListTile(
                title: Text(
                  domain,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  css.trim().replaceAll('\n', ' '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          _showEditDialog(context, model, domain, css),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _confirmDelete(context, model, domain),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () =>
            _showEditDialog(context, context.read<BrowserModel>(), null, null),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    BrowserModel model,
    String? initialDomain,
    String? initialCss,
  ) {
    final domainController = TextEditingController(text: initialDomain);
    final cssController = TextEditingController(text: initialCss);
    final isNew = initialDomain == null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNew ? 'Add CSS Rule' : 'Edit CSS Rule'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: domainController,
                decoration: const InputDecoration(
                  labelText: 'Domain (e.g., mail.google.com)',
                  border: OutlineInputBorder(),
                ),
                enabled:
                    isNew, // Lock domain when editing to simplify logic (or allow swap if key changes)
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: cssController,
                  decoration: const InputDecoration(
                    labelText: 'CSS Code',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (domainController.text.isNotEmpty) {
                model.addOrUpdateCssRule(
                  domainController.text.trim(),
                  cssController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, BrowserModel model, String domain) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule?'),
        content: Text('Are you sure you want to remove CSS for $domain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              model.removeCssRule(domain);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
