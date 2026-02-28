class Rating {
  final double rate;
  final int count;

  const Rating({required this.rate, required this.count});

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
        rate: (json['rate'] as num).toDouble(),
        count: json['count'] as int,
      );
}

class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final Rating rating;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
        description: json['description'] as String,
        category: json['category'] as String,
        image: json['image'] as String,
        rating: Rating.fromJson(json['rating'] as Map<String, dynamic>),
      );
}
