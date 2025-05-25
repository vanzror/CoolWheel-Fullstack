class UserData {
  static final UserData _instance = UserData._internal();

  factory UserData() {
    return _instance;
  }

  UserData._internal();

  String fullName = '';
  String email = '';
  String phone = '';
  String dob = '';
  String weight = '';
  String height = '';
  String emergencyContactName = '';
  String emergencyContactPhone = '';
  String age = '';
}
