class AppUser {
  final String name;
  final String email;
  final String role;
  final String phone;
  final String company;
  final String location;
  final String bio;
  final bool   profileComplete;

  const AppUser({
    required this.name,
    required this.email,
    required this.role,
    this.phone           = '',
    this.company         = '',
    this.location        = '',
    this.bio             = '',
    this.profileComplete = false,
  });

  factory AppUser.fromMap(Map<String, dynamic> d) => AppUser(
    name:            d['name']            ?? '',
    email:           d['email']           ?? '',
    role:            d['role']            ?? '',
    phone:           d['phone']           ?? '',
    company:         d['company']         ?? '',
    location:        d['location']        ?? '',
    bio:             d['bio']             ?? '',
    profileComplete: d['profileComplete'] ?? false,
  );
}