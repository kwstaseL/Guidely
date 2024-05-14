import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:guidely/models/data/tour_creation_data.dart';
import 'package:guidely/models/entities/user.dart';

enum TourState {
  upcoming,
  live,
  past,
}

class Tour {
  Tour({
    required this.tourDetails,
    required this.uid,
    this.duration = const TimeOfDay(hour: 2, minute: 0),
    this.images = const [],
    required this.organizer,
  });

  final TourCreationData tourDetails;
  final TimeOfDay duration;
  final List<String> images;
  final User organizer;
  final String uid;

  final List<String> registeredUsers = [];

  final TourState state = TourState.upcoming;
  final double rating = 4.0;

  get country => tourDetails.waypoints![0].address.split(',').last;
  get location => tourDetails.waypoints![0].address.split(',').first;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'tourDetails': tourDetails.toMap(),
      'location': location,
      'country': country,
      'duration': duration.hour,
      'images': images,
      'organizer': organizer.toMap(),
      'state': state.toString().split('.').last,
      'rating': rating,
    };
  }

  factory Tour.fromMap(Map<String, dynamic> map) {
    return Tour(
      tourDetails: TourCreationData.fromMap(map['tourDetails']),
      duration: TimeOfDay(hour: map['duration'] ?? 0, minute: 0),
      images: List<String>.from(map['images'] ?? []),
      organizer: User.fromMap(map['organizer']),
      uid: map['uid'],
    );
  }

  factory Tour.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Tour(
      uid: doc.id,
      tourDetails: TourCreationData.fromMap(data['tourDetails']),
      duration: TimeOfDay(hour: data['duration'] ?? 0, minute: 0),
      images: List<String>.from(data['images'] ?? []),
      organizer: User.fromMap(data['organizer']),
    );
  }

  @override
  String toString() {
    return 'Tour(tourDetails: $tourDetails, duration: $duration, images: $images, organizer: $organizer, state: $state, rating: $rating)';
  }
}
