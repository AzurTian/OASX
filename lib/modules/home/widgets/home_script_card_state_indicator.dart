part of 'home_script_card.dart';

class _ScriptStateIndicator extends StatelessWidget {
  const _ScriptStateIndicator({required this.state});

  final ScriptState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: switch (state) {
        ScriptState.running => const SpinKitChasingDots(
            color: Colors.green,
            size: 22,
          ),
        ScriptState.inactive =>
          const Icon(Icons.donut_large, size: 24, color: Colors.grey),
        ScriptState.warning =>
          const SpinKitDoubleBounce(color: Colors.orange, size: 24),
        ScriptState.updating => const Icon(
            Icons.browser_updated_rounded,
            size: 24,
            color: Colors.blue,
          ),
      },
    );
  }
}
