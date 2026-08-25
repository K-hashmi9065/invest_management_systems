class WithdrawalModel {
  final int id;
  final int memberId;
  final String memberName;
  final int amountPaise;
  final String status;
  final String requestedAt;
  final String? approvedBy;
  final String? approvedAt;
  final String? remarks;

  WithdrawalModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amountPaise,
    required this.status,
    required this.requestedAt,
    this.approvedBy,
    this.approvedAt,
    this.remarks,
  });

  factory WithdrawalModel.fromMap(Map<String, dynamic> map, {String memberName = ''}) {
    return WithdrawalModel(
      id: map['id'] as int,
      memberId: map['member_id'] as int,
      memberName: memberName.isNotEmpty ? memberName : 'Member #${map['member_id']}',
      amountPaise: map['amount_paise'] as int,
      status: map['status'] as String,
      requestedAt: map['requested_at'] as String,
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] as String?,
      remarks: map['remarks'] as String?,
    );
  }
}
