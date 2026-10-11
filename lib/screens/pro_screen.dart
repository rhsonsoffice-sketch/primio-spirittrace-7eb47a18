import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/pro_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/pro_panel.dart';

/// Opens the Pro screen on top of whatever is showing, without disturbing an
/// active investigation underneath.
Future<void> openProScreen(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProScreen()));

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t('proTitle'))),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          child: ProSection(),
        ),
      ),
    );
  }
}

/// Connects [ProPanel] to the app-global [ProProvider].
class ProSection extends StatelessWidget {
  const ProSection({super.key});

  @override
  Widget build(BuildContext context) {
    final pro = context.watch<ProProvider>();
    final l10n = context.l10n;

    String? message;
    var tone = ProMessageTone.info;
    if (pro.noticeKey != null) {
      message = l10n.t(pro.noticeKey!);
      tone = pro.noticeKey == 'proRestored'
          ? ProMessageTone.success
          : ProMessageTone.info;
    } else if (pro.status == ProStatus.pending) {
      message = l10n.t('proPending');
    } else if (pro.status == ProStatus.cancelled) {
      message = l10n.t('proCancelled');
    } else if (pro.status == ProStatus.error && pro.errorKey != null) {
      final detail = pro.errorDetail;
      message = detail == null || detail.isEmpty
          ? l10n.t(pro.errorKey!)
          : '${l10n.t(pro.errorKey!)}\n($detail)';
      tone = ProMessageTone.error;
    }

    return ProPanel(
      isPro: pro.isPro,
      storeSupported: pro.storeSupported,
      loading: pro.status == ProStatus.loading,
      busy: pro.busy,
      restoring: pro.restoring,
      price: pro.product?.price,
      message: message,
      tone: tone,
      onBuy: pro.canBuy ? pro.buy : null,
      onRestore:
          pro.storeSupported && !pro.restoring && !pro.busy ? pro.restore : null,
      onRetry: pro.storeSupported &&
              pro.product == null &&
              pro.status == ProStatus.error
          ? pro.loadProduct
          : null,
    );
  }
}
