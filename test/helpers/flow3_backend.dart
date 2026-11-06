import 'flow1_backend.dart';

Map<String, dynamic> testReward({
  int price = 200,
  int stock = 3,
  String type = 'voucher',
}) => {
  'id': 'server-reward',
  'title': 'Server Café',
  'category': 'food_drinks',
  'priceCoins': price,
  'stockRemaining': stock,
  'status': 'active',
  'termsVersion': 'terms-1',
  'termsText': 'Server voucher terms',
  'description': 'Server description',
  'usageLocations': ['Server café location'],
  'redemptionInstructions': 'Show to admin',
  'fulfillmentType': type,
  'validDays': 30,
};

class Flow3TestBackend extends Flow1TestBackend {
  int available = 310, held = 0, dailyDay = 1, dailyCoins = 5, stock = 3;
  bool claimedDaily = false, claimedMilestone = false;
  String voucherStatus = 'unused', fulfillment = 'voucher';
  final redemptions = <Map<String, dynamic>>[],
      ledger = <Map<String, dynamic>>[];
  final receipts = <String, Map<String, dynamic>>{};
  @override
  Map<String, dynamic> respond(String operation, Map<String, dynamic> input) {
    switch (operation) {
      case 'getAccount':
        return {
          ...super.respond(operation, input),
          'wallet': {'availableCoins': available, 'heldCoins': held},
          'daily': {
            'dayKey': '2026-11-06',
            'serverTime': '2026-11-05T17:00:01Z',
            'streakDay': dailyDay,
            'coins': dailyCoins,
            'rewards': [5, 10, 15, 30, 50, 70, 100],
            'alreadyClaimed': claimedDaily,
          },
        };
      case 'getEventMilestones':
        return {
          'verifiedEventCount': 2,
          'nextMilestone': {'id': 'server-next'},
          'items': [
            {
              'id': 'server-first',
              'title': 'Server First',
              'requiredEvents': 1,
              'rewardCoins': 50,
              'description': '',
              'version': 4,
              'unlocked': true,
              'claimed': claimedMilestone,
              'remainingEvents': 0,
            },
            {
              'id': 'server-next',
              'title': 'Server Next',
              'requiredEvents': 3,
              'rewardCoins': 100,
              'description': '',
              'version': 2,
              'unlocked': false,
              'claimed': false,
              'remainingEvents': 1,
            },
          ],
        };
      case 'getPublicCatalog':
        if (input['kind'] == 'rewards') {
          return {
            'items': [testReward(stock: stock, type: fulfillment)],
            'nextCursor': null,
          };
        }
      case 'listOwned':
        if (['redemptions', 'vouchers', 'ledger'].contains(input['kind'])) {
          return {
            'items': input['kind'] == 'redemptions'
                ? redemptions
                : input['kind'] == 'ledger'
                ? ledger
                : [
                    for (final r in redemptions)
                      if (r['voucherId'] != null)
                        {'id': r['voucherId'], 'status': voucherStatus},
                  ],
            'nextCursor': null,
          };
        }
      case 'claimDailyCheckin':
        if (!claimedDaily) {
          claimedDaily = true;
          available += dailyCoins;
        }
        return {
          'wallet': {'availableCoins': available, 'heldCoins': held},
        };
      case 'claimEventMilestone':
        if (!claimedMilestone) {
          claimedMilestone = true;
          available += 50;
        }
        return {
          'milestoneId': input['milestoneId'],
          'wallet': {'availableCoins': available, 'heldCoins': held},
        };
      case 'redeemReward':
        final id = input['requestId'] as String;
        if (receipts.containsKey(id)) return receipts[id]!;
        available -= 200;
        stock--;
        final redemptionId = 'redemption-${redemptions.length + 1}';
        redemptions.add({
          'id': redemptionId,
          'rewardId': 'server-reward',
          'priceCoinsSnapshot': 200,
          'rewardTitleSnapshot': 'Server Café',
          'rewardSnapshot': testReward(type: fulfillment),
          'status': 'issued',
          'voucherId': fulfillment == 'voucher'
              ? 'voucher-$redemptionId'
              : null,
          'redeemedAt': '2026-11-06T00:00:00Z',
          'expiresAt': '2030-12-31T00:00:00Z',
        });
        ledger.add({
          'id': id,
          'type': 'redeem_reward',
          'deltaAvailable': -200,
          'deltaHeld': 0,
          'sourceId': redemptionId,
          'createdAt': '2026-11-06T00:00:00Z',
        });
        return receipts[id] = {
          'redemptionId': redemptionId,
          'wallet': {'availableCoins': available, 'heldCoins': held},
        };
      case 'getOperationStatus':
        return {'result': receipts[input['operationId']]};
      case 'getVoucherCode':
        return {
          'code': 'test-only-voucher-code-12345678901234567890123',
          'qrPayload': 'evia:voucher:server:signed-secret',
          'expiresAt': '2030-12-31T00:00:00Z',
        };
    }
    return super.respond(operation, input);
  }
}
