class ContributionModel {
  final int id;
  final int memberId;
  final String memberName;
  final int amountPaise;
  final String contributionDate;
  final String paymentMode;
  final String? referenceNo;
  final String status;
  final String? approvedBy;
  final String? approvedAt;
  final String? remarks;
  final String createdAt;

  ContributionModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amountPaise,
    required this.contributionDate,
    required this.paymentMode,
    this.referenceNo,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.remarks,
    required this.createdAt,
  });

  factory ContributionModel.fromMap(Map<String, dynamic> map, {String memberName = ''}) {
    return ContributionModel(
      id: map['id'] as int,
      memberId: map['member_id'] as int,
      memberName: memberName.isNotEmpty ? memberName : (map['member_name'] as String? ?? 'Member #${map['member_id']}'),
      amountPaise: map['amount_paise'] as int,
      contributionDate: map['contribution_date'] as String,
      paymentMode: map['payment_mode'] as String,
      referenceNo: map['reference_no'] as String?,
      status: map['status'] as String,
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] as String?,
      remarks: map['remarks'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
