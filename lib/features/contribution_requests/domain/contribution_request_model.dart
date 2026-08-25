class ContributionRequestModel {
  final int id;
  final int memberId;
  final String memberName;
  final int amountPaise;
  final String paymentMode;
  final String status;
  final String requestedAt;
  final String? reviewedBy;
  final String? reviewedAt;
  final String? remarks;

  ContributionRequestModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amountPaise,
    required this.paymentMode,
    required this.status,
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.remarks,
  });

  factory ContributionRequestModel.fromMap(Map<String, dynamic> map, {String memberName = ''}) {
    return ContributionRequestModel(
      id: map['id'] as int,
      memberId: map['member_id'] as int,
      memberName: memberName.isNotEmpty ? memberName : (map['member_name'] as String? ?? 'Member #${map['member_id']}'),
      amountPaise: map['amount_paise'] as int,
      paymentMode: map['payment_mode'] as String,
      status: map['status'] as String,
      requestedAt: map['requested_at'] as String,
      reviewedBy: map['reviewed_by'] as String?,
      reviewedAt: map['reviewed_at'] as String?,
      remarks: map['remarks'] as String?,
    );
  }
}
