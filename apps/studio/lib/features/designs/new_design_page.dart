import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:artlavka_core/artlavka_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import 'designs_controller.dart';

/// Upload a print: pick an image (uploaded to Cloudinary) or paste an image URL,
/// + title + category + product + royalty → creates a pending design + listing.
///
/// If Cloudinary isn't configured server-side, the upload fails gracefully and
/// the seller can still paste an image URL.
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

  XFile? _picked;
  int _pickedWidth = 0;
  int _pickedHeight = 0;
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

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final (w, h) = await _imageSize(bytes);
    if (!mounted) return;
    setState(() {
      _picked = file;
      _pickedWidth = w;
      _pickedHeight = h;
      _imageUrl.clear(); // a picked file takes precedence over a pasted URL
    });
  }

  Future<(int, int)> _imageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    return (image.width, image.height);
  }

  Future<void> _submit() async {
    final t = context.l10n;
    final title = _title.text.trim();
    final pastedUrl = _imageUrl.text.trim();
    final royalty = int.tryParse(_royalty.text.trim()) ?? -1;
    if (title.isEmpty ||
        (_picked == null && pastedUrl.isEmpty) ||
        _productTypeId == null) {
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

    // 1) Resolve the image URL: upload the picked file, or use the pasted URL.
    String imageUrl;
    int widthPx = 3000;
    int heightPx = 3000;
    if (_picked != null) {
      final uploaded = await ref
          .read(storageServiceProvider)
          .uploadPrintImage(filePath: _picked!.path);
      if (!mounted) return;
      final url = uploaded.fold((u) => u, (f) {
        _snack(_msg(f.code));
        return null;
      });
      if (url == null) {
        setState(() => _submitting = false);
        return;
      }
      imageUrl = url;
      widthPx = _pickedWidth > 0 ? _pickedWidth : 3000;
      heightPx = _pickedHeight > 0 ? _pickedHeight : 3000;
    } else {
      imageUrl = pastedUrl;
    }

    // 2) Create the design, then its listing.
    final repo = ref.read(designRepositoryProvider);
    final created = await repo.createDesign(
      title: title,
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      previewUrl: imageUrl,
      printFilePath: imageUrl,
      widthPx: widthPx,
      heightPx: heightPx,
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
    FailureCode.uploadTooSmall =>
      'Image too small (min ${AppConstants.minPrintWidthPx}px)',
    FailureCode.uploadWrongFormat => 'Use a PNG or JPG image',
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
          // Live preview: picked file > pasted URL > placeholder.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: AspectRatio(
              aspectRatio: 1,
              child: _picked != null
                  ? Image.file(File(_picked!.path), fit: BoxFit.cover)
                  : url.isEmpty
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
          const SizedBox(height: AppTheme.space),

          OutlinedButton.icon(
            onPressed: _submitting ? null : _pick,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(t.uploadPickImage),
          ),
          if (_picked != null && _pickedWidth > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$_pickedWidth×$_pickedHeight px',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: AppTheme.space * 2),

          _field(_title, t.fieldDesignTitle),
          _field(_description, t.fieldDescription, maxLines: 2),

          // URL fallback — only when no file is picked.
          if (_picked == null)
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
