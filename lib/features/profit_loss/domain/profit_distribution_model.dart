class ProfitDistributionModel {
  final int id;
  final int investmentId;
  final String investmentName;
  final int memberId;
  final String memberName;
  final double memberPercentage;
  final int profitAmountPaise;
  final String distributedAt;

  ProfitDistributionModel({
    required this.id,
    required this.investmentId,
    required this.investmentName,
    required this.memberId,
    required this.memberName,
    required this.memberPercentage,
    required this.profitAmountPaise,
    required this.distributedAt,
  });

  factory ProfitDistributionModel.fromMap(
    Map<String, dynamic> map, {
    String investmentName = '',
    String memberName = '',
  }) {
    return ProfitDistributionModel(
      id: map['id'] as int,
      investmentId: map['investment_id'] as int,
      investmentName: investmentName.isNotEmpty
          ? investmentName
          : 'Investment #${map['investment_id']}',
      memberId: map['member_id'] as int,
      memberName: memberName.isNotEmpty
          ? memberName
          : 'Member #${map['member_id']}',
      memberPercentage: (map['member_percentage'] as num).toDouble(),
      profitAmountPaise: map['profit_amount_paise'] as int,
      distributedAt: map['distributed_at'] as String,
    );
  }
}
