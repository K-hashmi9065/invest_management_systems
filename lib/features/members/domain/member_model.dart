class MemberModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String joinedDate;
  final String status;

  // Financial calculated fields
  final int totalContributionPaise;
  final double contributionPercentage;
  final int investmentSharePaise;
  final int allocatedProfitPaise;
  final int totalWithdrawalPaise;
  final int availableBalancePaise;

  MemberModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.joinedDate,
    required this.status,
    this.totalContributionPaise = 0,
    this.contributionPercentage = 0.0,
    this.investmentSharePaise = 0,
    this.allocatedProfitPaise = 0,
    this.totalWithdrawalPaise = 0,
    this.availableBalancePaise = 0,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map, {
    int totalContributionPaise = 0,
    double contributionPercentage = 0.0,
    int investmentSharePaise = 0,
    int allocatedProfitPaise = 0,
    int totalWithdrawalPaise = 0,
    int availableBalancePaise = 0,
  }) {
    return MemberModel(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      joinedDate: map['joined_date'] as String,
      status: map['status'] as String,
      totalContributionPaise: totalContributionPaise,
      contributionPercentage: contributionPercentage,
      investmentSharePaise: investmentSharePaise,
      allocatedProfitPaise: allocatedProfitPaise,
      totalWithdrawalPaise: totalWithdrawalPaise,
      availableBalancePaise: availableBalancePaise,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'joined_date': joinedDate,
      'status': status,
    };
  }
}
