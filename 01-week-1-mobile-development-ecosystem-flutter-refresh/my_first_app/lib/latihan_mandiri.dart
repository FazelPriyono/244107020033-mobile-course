double hitungLuasPersegiPanjang(double panjang, double lebar) {
  return panjang * lebar;
}

class Profil {
  String nama;
  String nim;
  String? email;

  Profil({required this.nama, required this.nim, this.email});
}

void main() {
  double luas = hitungLuasPersegiPanjang(10.0, 5.0);
  print('Luas: $luas');

  Profil user = Profil(nama: 'Alya', nim: '123456', email: null);
  print('Nama: ${user.nama}');
  print('Email: ${user.email ?? 'Email belum diisi'}');
}
