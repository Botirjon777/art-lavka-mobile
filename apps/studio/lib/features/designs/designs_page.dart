import 'package:artlavka_core/artlavka_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap/result_x.dart';
import '../../l10n/l10n.dart';
import '../../ui/async_views.dart';
import '../auth/auth_controller.dart';
import 'designs_controller.dart';

/// Seller's designs with moderation status + a button to upload a new one.
class DesignsPage extends ConsumerWidget {
  const DesignsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final designs = ref.watch(myDesignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.designsTitle),
        actions: [
          IconButton(
            tooltip: t.actionSignOut,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/designs/new'),
        icon: const Icon(Icons.add),
        label: Text(t.newDesign),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myDesignsProvider),
        child: designs.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorRetryView(
            message: failureMessage(context, e),
            onRetry: () => ref.invalidate(myDesignsProvider),
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    EmptyView(
                      message: t.designsEmpty,
                      icon: Icons.image_outlined,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.space),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _DesignTile(design: list[i]),
                ),
        ),
      ),
    );
  }
}

class _DesignTile extends StatelessWidget {
  const _DesignTile({required this.design});
  final Design design;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: design.previewUrl.isEmpty
              ? Container(color: AppColors.surfaceMuted)
              : CachedNetworkImage(
                  imageUrl: design.previewUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: AppColors.surfaceMuted),
                  errorWidget: (_, _, _) =>
                      Container(color: AppColors.surfaceMuted),
                ),
        ),
      ),
      title: Text(design.title),
      subtitle: design.rejectionReason != null
          ? Text(
              design.rejectionReason!,
              style: const TextStyle(color: AppColors.error),
            )
          : null,
      trailing: _StatusChip(status: design.status),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final DesignStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      DesignStatus.approved => (const Color(0xFFDCEFE2), AppColors.success),
      DesignStatus.pending => (const Color(0xFFF6E9CC), AppColors.warning),
      DesignStatus.rejected => (const Color(0xFFF4D9D6), AppColors.error),
      DesignStatus.draft => (AppColors.surfaceMuted, AppColors.inkMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        designStatusLabel(context.l10n, status),
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
