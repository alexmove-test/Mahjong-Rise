/// 24 облика дома. Первое состояние бесплатное, каждое следующее покупается.
abstract final class HouseUpgrade {
  static const stateCount = 24;
  static const firstState = 1;

  static bool canAdvance(int state) =>
      state >= firstState && state < stateCount;

  static int clampState(int state) => state.clamp(firstState, stateCount);

  /// Цена перехода из состояния [state] в следующее: 100 + 50 × (L − 1).
  static int priceAfter(int state) {
    if (!canAdvance(state)) {
      throw ArgumentError.value(state, 'state', 'no next house state');
    }
    return 100 + 50 * (state - 1);
  }

  static int? nextState(int state) => canAdvance(state) ? state + 1 : null;

  /// Кадр кампании 0 — бесплатное первое состояние. Уже видимый кадр сохраняется.
  static int fromCampaignFrame(int frame) {
    if (frame < firstState) return firstState;
    return clampState(frame);
  }
}

enum HouseBuyStatus { purchased, insufficient, maxed, unavailable, failed }

/// Итог одной попытки купить следующее состояние дома.
class HouseBuyResult {
  const HouseBuyResult({
    required this.status,
    required this.balance,
    required this.houseState,
    this.price = 0,
    this.shortfall = 0,
  });

  final HouseBuyStatus status;
  final int balance;
  final int houseState;
  final int price;
  final int shortfall;

  bool get purchased => status == HouseBuyStatus.purchased;

  const HouseBuyResult.unavailable({
    required int balance,
    required int houseState,
  }) : this(
         status: HouseBuyStatus.unavailable,
         balance: balance,
         houseState: houseState,
       );

  const HouseBuyResult.failed({required int balance, required int houseState})
    : this(
        status: HouseBuyStatus.failed,
        balance: balance,
        houseState: houseState,
      );
}
