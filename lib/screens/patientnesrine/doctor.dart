class Doctor {
  final String name;
  final String specialty;
  final String hospital;
  final double rating;
  final int reviews;
  final int experience; // Years
  final String about;
  final String imagePath; // Asset or Network URL

  Doctor({
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.about,
    required this.imagePath,
  });
}

// Mock Data
final List<Doctor> mockDoctors = [
  Doctor(
    name: "Dr. Jennifer Smith",
    specialty: "Orthopedist",
    hospital: "Mayo Clinic",
    rating: 4.8,
    reviews: 120,
    experience: 12,
    about: "Dr. Jennifer Smith is a highly skilled Orthopedist with over 12 years of experience. She specializes in foot and ankle surgery and is dedicated to providing the best care for her patients.",
    imagePath: "assets/images/doc1.png", // Placeholder
  ),
  Doctor(
    name: "Dr. Brand Warner",
    specialty: "Neurologist",
    hospital: "Johns Hopkins",
    rating: 4.9,
    reviews: 340,
    experience: 15,
    about: "Dr. Warner is a leading Neurologist known for his expertise in treating complex neurological disorders. He has been practicing for over 15 years.",
    imagePath: "assets/images/doc2.png", // Placeholder
  ),
  Doctor(
    name: "Dr. Julia Roman",
    specialty: "Cardiologist",
    hospital: "Cleveland Clinic",
    rating: 4.7,
    reviews: 89,
    experience: 8,
    about: "Dr. Roman is a dedicated Cardiologist focused on heart health and preventative care.",
    imagePath: "assets/images/doc3.png", // Placeholder
  ),
];