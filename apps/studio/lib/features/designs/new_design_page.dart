import 'package:artlavka_core/artlavka_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import 'designs_controller.dart';

/// Upload a print: title + image URL (live preview) + category + product +
/// royalty → creates a design (status pending) and its listing.
///
/// NOTE: until S3 is wired, the print is referenced by a pasted image URL rather
/// than a device-file upload (the presigned-upload path is ready server-side).
class NewDesignPage extends ConsumerStatefulWidget {
  const NewDesignPage({super.key});

  @override
  ConsumerState<NewDesignPage> createState() => _NewDesignPageState();
}

class _NewDesignPageState extends ConsumerState<NewDesignPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  final _royalty = TextEditingController(text: '20000');

  String? _categoryId;
  String? _productTypeId;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _royalty.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final title = _title.text.trim();
    final url = _imageUrl.text.trim();
    final royalty = int.tryParse(_royalty.text.trim()) ?? -1;
    if (title.isEmpty || url.isEmpty || _productTypeId == null) {
      _snack(t.valRequired);
      return;
    }
    if (royalty < AppConstants.royaltyMinUzs ||
        royalty > AppConstants.royaltyMaxUzs) {
      _snack(
        'Royalty ${AppConstants.royaltyMinUzs}–${AppConstants.royaltyMaxUzs}',
      );
      return;
    }

    setState(() => _submitting = true);
    final repo = ref.read(designRepositoryProvider);
    final created = await repo.createDesign(
      title: title,
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      previewUrl: url,
      printFilePath: url,
      widthPx: 3000,
      heightPx: 3000,
      categoryIds: _categoryId != null ? [_categoryId!] : const [],
    );
    if (!mounted) return;

    await created.fold(
      (design) async {
        final listed = await repo.upsertListing(
          designId: design.id,
          productTypeId: _productTypeId!,
          royaltyUzs: royalty,
        );
        if (!mounted) return;
        setState(() => _submitting = false);
        listed.fold((_) {
          ref.invalidate(myDesignsProvider);
          context.pop();
        }, (f) => _snack(_msg(f.code)));
      },
      (f) async {
        if (!mounted) return;
        setState(() => _submitting = false);
        _snack(_msg(f.code));
      },
    );
  }

  String _msg(String? code) => switch (code) {
    FailureCode.royaltyOutOfBounds =>
      'Royalty ${AppConstants.royaltyMinUzs}–${AppConstants.royaltyMaxUzs}',
    FailureCode.uploadTooSmall => 'Image is too small',
    _ => context.l10n.errServer,
  };

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final lang = ref.watch(localeProvider).languageCode;
    final products = ref.watch(productTypesProvider);
    final categories = ref.watch(categoriesProvider);
    final url = _imageUrl.text.trim();

    return Scaffold(
      appBar: AppBar(title: Text(t.newDesign)),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space * 2),
        children: [
          // Live preview.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: AspectRatio(
              aspectRatio: 1,
              child: url.isEmpty
                  ? Container(
                      color: AppColors.surfaceMuted,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.inkFaint,
                        size: 40,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: AppColors.surfaceMuted),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.surfaceMuted,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppTheme.space * 2),

          _field(_title, t.fieldDesignTitle),
          _field(_description, t.fieldDescription, maxLines: 2),
          TextField(
            controller: _imageUrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: t.fieldImageUrl,
              hintText: t.fieldImageUrlHint,
              helperText: ' ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTheme.space),

          Text(t.fieldCategory, style: Theme.of(context).textTheme.titleSmall),
          categories.maybeWhen(
            data: (cats) => Wrap(
              spacing: 8,
              children: [
                for (final c in cats)
                  ChoiceChip(
                    label: Text(c.nameFor(lang)),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(
                      () => _categoryId = _categoryId == c.id ? null : c.id,
                    ),
                  ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppTheme.space),

          products.maybeWhen(
            data: (types) => DropdownButtonFormField<String>(
              initialValue: _productTypeId,
              decoration: InputDecoration(labelText: t.fieldProduct),
              items: [
                for (final p in types)
                  DropdownMenuItem(value: p.id, child: Text(p.nameFor(lang))),
              ],
              onChanged: (v) => setState(() => _productTypeId = v),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppTheme.space),

          TextField(
            controller: _royalty,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: t.fieldRoyalty),
          ),
          const SizedBox(height: AppTheme.space * 2),

          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.onAccent,
                    ),
                  )
                : Text(t.uploadSubmit),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, helperText: ' '),
        ),
      );
}
