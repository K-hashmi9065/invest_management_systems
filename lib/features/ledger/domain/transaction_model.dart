class TransactionModel {
  final int id;
  final String transactionType;
  final int? memberId;
  final String? memberName;
  final int amountPaise;
  final String date;
  final String status;
  final String? referenceNo;
  final String? remarks;
  final String createdBy;
  final String? approvedBy;

  TransactionModel({
    required this.id,
    required this.transactionType,
    this.memberId,
    this.memberName,
    required this.amountPaise,
    required this.date,
    required this.status,
    this.referenceNo,
    this.remarks,
    required this.createdBy,
    this.approvedBy,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, {String? memberName}) {
    return TransactionModel(
      id: map['id'] as int,
      transactionType: map['transaction_type'] as String,
      memberId: map['member_id'] as int?,
      memberName: memberName ?? map['member_name'] as String?,
      amountPaise: map['amount_paise'] as int,
      date: map['date'] as String,
      status: map['status'] as String,
      referenceNo: map['reference_no'] as String?,
      remarks: map['remarks'] as String?,
      createdBy: map['created_by'] as String,
      approvedBy: map['approved_by'] as String?,
    );
  }
}
