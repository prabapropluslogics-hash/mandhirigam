import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/debug/phase21_render_gate.dart';

void main() {
  test('scheduled renders run one at a time, in order', () async {
    final Phase21RenderGate gate = Phase21RenderGate();
    final List<int> order = <int>[];
    final Future<void> first = gate.schedule(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      order.add(1);
    });
    final Future<void> second = gate.schedule(() async {
      order.add(2);
    });
    await Future.wait(<Future<void>>[first, second]);
    expect(order, <int>[1, 2]);
  });

  test('a result for one page is rejected by another page or a newer render',
      () {
    expect(
      phase21ResultIsCurrent(
        requestedPage: 20,
        requestedGeneration: 1,
        currentPage: 28,
        currentGeneration: 1,
        closed: false,
      ),
      isFalse,
    );
    expect(
      phase21ResultIsCurrent(
        requestedPage: 20,
        requestedGeneration: 1,
        currentPage: 20,
        currentGeneration: 2,
        closed: false,
      ),
      isFalse,
    );
    expect(
      phase21ResultIsCurrent(
        requestedPage: 11,
        requestedGeneration: 1,
        currentPage: 11,
        currentGeneration: 1,
        closed: true,
      ),
      isFalse,
    );
    expect(
      phase21ResultIsCurrent(
        requestedPage: 11,
        requestedGeneration: 3,
        currentPage: 11,
        currentGeneration: 3,
        closed: false,
      ),
      isTrue,
    );
  });
}
