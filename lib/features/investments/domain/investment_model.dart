class InvestmentModel {
  final int id;
  final String name;
  final String type;
  final int amountPaise;
  final String investmentDate;
  final int periodMonths;
  final int expectedReturnPaise;
  final int actualReturnPaise;
  final int currentValuePaise;
  final String status;
  final String? remarks;
  final String createdBy;

  InvestmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.amountPaise,
    required this.investmentDate,
    required this.periodMonths,
    required this.expectedReturnPaise,
    this.actualReturnPaise = 0,
    required this.currentValuePaise,
    required this.status,
    this.remarks,
    required this.createdBy,
  });

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      amountPaise: map['amount_paise'] as int,
      investmentDate: map['investment_date'] as String,
      periodMonths: map['period_months'] as int,
      expectedReturnPaise: map['expected_return_paise'] as int,
      actualReturnPaise: map['actual_return_paise'] as int? ?? 0,
      currentValuePaise: map['current_value_paise'] as int,
      status: map['status'] as String,
      remarks: map['remarks'] as String?,
      createdBy: map['created_by'] as String,
    );
  }
}
