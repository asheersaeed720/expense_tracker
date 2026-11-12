import 'package:expense_tracker/core/constants/default_categories.dart';
import 'package:expense_tracker/core/enums/category_type.dart';
import 'package:expense_tracker/core/models/category.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/utils/icon_name_mapper.dart';
import 'package:expense_tracker/core/widgets/scaffold_with_fab.dart';
import 'package:expense_tracker/features/categories/providers/categories_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final expense = categoriesAsync.valueOrNull
            ?.where((c) => c.type == CategoryType.expense)
            .toList() ??
        const [];
    final income = categoriesAsync.valueOrNull
            ?.where((c) => c.type == CategoryType.income)
            .toList() ??
        const [];

    return ScaffoldWithFab(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-categories',
        onPressed: () => _openCreate(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: 'Expense categories',
              categories: expense,
              onTap: (c) => _openEdit(context, ref, c),
              onDelete: (c) => _delete(context, ref, c),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Income categories',
              categories: income,
              onTap: (c) => _openEdit(context, ref, c),
              onDelete: (c) => _delete(context, ref, c),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_CategoryFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _CategoryFormSheet(),
    );

    if (result == null || !context.mounted) return;

    try {
      await ref.read(categoriesServiceProvider).createCategory(
            name: result.name,
            type: result.type,
            icon: result.icon,
          );
      if (context.mounted) {
        showAppSnackBar(context, message: 'Category created.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _openEdit(BuildContext context, WidgetRef ref, Category category) async {
    final result = await showModalBottomSheet<_CategoryFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CategoryFormSheet(initial: category),
    );

    if (result == null || !context.mounted) return;

    try {
      await ref.read(categoriesServiceProvider).updateCategory(
            id: category.id,
            name: result.name,
            icon: result.icon,
          );
      if (context.mounted) {
        showAppSnackBar(context, message: 'Category updated.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Category category) async {
    if (category.isProtectedDefault) {
      showAppSnackBar(
        context,
        message: 'Default categories cannot be deleted.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(categoriesServiceProvider).deleteCategory(category.id);
      if (context.mounted) {
        showAppSnackBar(context, message: 'Category deleted.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.categories,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final List<Category> categories;
  final void Function(Category) onTap;
  final void Function(Category) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...categories.map(
          (c) => Card(
            child: ListTile(
              leading: Icon(IconNameMapper.categoryIcon(c.icon)),
              title: Text(c.name),
              subtitle: c.isProtectedDefault
                  ? const Text('Default')
                  : const Text('Custom'),
              trailing: c.isProtectedDefault
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onDelete(c),
                    ),
              onTap: c.isProtectedDefault ? null : () => onTap(c),
            ),
          ),
        ),
      ],
    );
  }
}

typedef _CategoryFormResult = ({String name, CategoryType type, String icon});

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.initial});

  final Category? initial;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late CategoryType _type;
  late String _icon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _type = widget.initial?.type ?? CategoryType.expense;
    _icon = widget.initial?.icon ?? DefaultCategories.selectableIcons.first.$1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      (name: _nameController.text.trim(), type: _type, icon: _icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isEdit = widget.initial != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit category' : 'New category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            if (!isEdit) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<CategoryType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: CategoryType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t == CategoryType.expense ? 'Expense' : 'Income'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _icon,
              decoration: const InputDecoration(labelText: 'Icon'),
              items: DefaultCategories.selectableIcons
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.$1,
                      child: Row(
                        children: [
                          Icon(IconNameMapper.categoryIcon(entry.$1)),
                          const SizedBox(width: 8),
                          Text(entry.$2),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _icon = v);
              },
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: Text(isEdit ? 'Save' : 'Create')),
          ],
        ),
      ),
    );
  }
}
