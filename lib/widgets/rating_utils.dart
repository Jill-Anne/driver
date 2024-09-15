import 'package:flutter/material.dart';

List<Widget> getStarRating(double rating) {
  const double starSize = 15.0; // Define the size for the star

  List<Widget> stars = [];
  int fullStars = rating.floor();
  bool hasHalfStar = rating - fullStars >= 0.5;

  // Add full stars
  for (int i = 0; i < fullStars; i++) {
    stars.add(
      Icon(
        Icons.star,
        color: Colors.amber,
        size: starSize, // Set the size of the star
      ),
    );
  }

  // Add half star if needed
  if (hasHalfStar) {
    stars.add(
      Icon(
        Icons.star_half,
        color: Colors.amber,
        size: starSize, // Set the size of the half star
      ),
    );
  }

  // Add empty stars to make a total of 5 stars
  while (stars.length < 5) {
    stars.add(
      Icon(
        Icons.star_border,
        color: Colors.amber,
        size: starSize, // Set the size of the empty star
      ),
    );
  }

  return stars;
}
