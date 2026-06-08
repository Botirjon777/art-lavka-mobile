import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/core_providers.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/loading_button.dart';

/// Show the rating sheet for [orderItemId]. Resolves `true` if a review was
/// submitted (caller refreshes the order).
Future<bool> showReviewSheet(BuildContext context, String orderItemId) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReviewSheet(orderItemId: orderItemId),
  );
  return result ?? false;
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.orderItemId});
  final String orderItemId;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final result = await ref
        .read(orderRepositoryProvider)
        .submitReview(
          orderItemId: widget.orderItemId,
          rating: _rating,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (_) => Navigator.of(context).pop(true),
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedFailure(context.l10n, failure.code))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.space * 3,
        right: AppTheme.space * 3,
        top: AppTheme.space * 3,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.space * 3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.reviewTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space * 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 36,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space),
          TextField(
            controller: _comment,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(hintText: t.reviewCommentHint),
          ),
          const SizedBox(height: AppTheme.space * 2),
          LoadingButton(
            label: t.reviewSubmit,
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
