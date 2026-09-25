import 'package:flutter/widgets.dart';

import 'ad_gateway.dart';

/// The banner strip, as the app places it.
///
/// **Takes no space at all when there is no ad.** Not a grey placeholder, not
/// a reserved height: an app that reserves space for an ad it may never load
/// looks broken to the majority of users who see no ad, and to every user once
/// they buy Pro.
///
/// [allowed] is the policy answer, passed in rather than computed here, so the
/// widget stays dumb and the rules stay in one testable place.
class AdSlot extends StatefulWidget {
  const AdSlot({
    required this.gateway,
    required this.allowed,
    super.key,
  });

  final AdGateway gateway;
  final bool allowed;

  @override
  State<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<AdSlot> {
  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(AdSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway) _listen();
  }

  void _listen() {
    final gateway = widget.gateway;
    if (gateway is AdMobGatewayRebuilds) {
      (gateway as AdMobGatewayRebuilds).onChanged = () {
        if (mounted) setState(() {});
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.allowed) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final ad = widget.gateway.banner(width: constraints.maxWidth);
        if (ad == null) return const SizedBox.shrink();
        return Align(alignment: Alignment.bottomCenter, child: ad);
      },
    );
  }
}

/// A gateway that can tell the slot to rebuild when an ad finishes loading.
///
/// Kept as a separate interface so [AdSlot] does not import the SDK-backed
/// implementation, and so [NoAds] is not forced to carry a callback it would
/// never fire.
abstract interface class AdMobGatewayRebuilds {
  set onChanged(VoidCallback? callback);
}
