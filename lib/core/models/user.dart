class UserName {
  final String firstname;
  final String lastname;

  const UserName({required this.firstname, required this.lastname});

  factory UserName.fromJson(Map<String, dynamic> json) => UserName(
        firstname: json['firstname'] as String,
        lastname: json['lastname'] as String,
      );

  Map<String, dynamic> toJson() => {
        'firstname': firstname,
        'lastname': lastname,
      };

  String get fullName => '$firstname $lastname';
}

class Address {
  final String city;
  final String street;
  final int number;
  final String zipcode;

  const Address({
    required this.city,
    required this.street,
    required this.number,
    required this.zipcode,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        city: json['city'] as String,
        street: json['street'] as String,
        number: json['number'] as int,
        zipcode: json['zipcode'] as String,
      );

  Map<String, dynamic> toJson() => {
        'city': city,
        'street': street,
        'number': number,
        'zipcode': zipcode,
      };

  String get formatted => '$number $street, $city $zipcode';
}

class User {
  final int id;
  final String email;
  final String username;
  final UserName name;
  final Address address;
  final String phone;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.address,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        username: json['username'] as String,
        name: UserName.fromJson(json['name'] as Map<String, dynamic>),
        address: Address.fromJson(json['address'] as Map<String, dynamic>),
        phone: json['phone'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'name': name.toJson(),
        'address': address.toJson(),
        'phone': phone,
      };
}
