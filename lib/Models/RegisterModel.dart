class RegisterModel{
  final String first_name, last_name, email, phone, birth, pass1, pass2;
  
  RegisterModel({required this.first_name,required this.last_name,required this.email,required this.phone,required this.birth,required this.pass1,required this.pass2,});

  Map<String, dynamic> toJson() => {
  'firstname': first_name,
  'lastname': last_name,
  'email': email,
  'phone_number': phone,
  'birthday': birth,
  'password1': pass1,
  'password2': pass2,
  };
}