import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/translations.dart';

class RatingAndReviewScreen extends StatefulWidget {
  final String bookingId;

  const RatingAndReviewScreen({super.key, required this.bookingId});

  @override
  State<RatingAndReviewScreen> createState() => _RatingAndReviewScreenState();
}

class _RatingAndReviewScreenState extends State<RatingAndReviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double roomRating = 0.0;
  double serviceRating = 0.0;
  double overallRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();
  String _locale = 'en-gb';
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locale = prefs.getString('locale') ?? 'en-gb';
    });
  }

  Future<void> _submitReview() async {
    if (_auth.currentUser == null) {
      Navigator.pushReplacementNamed(context, '/auth');
      return;
    }

    if (roomRating == 0 || serviceRating == 0 || overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('please_provide_all_ratings', _locale),
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await _firestore.collection('reviews').add({
        'userId': _auth.currentUser!.uid,
        'bookingId': widget.bookingId,
        'roomRating': roomRating,
        'serviceRating': serviceRating,
        'overallRating': overallRating,
        'review': _reviewController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('review_submitted_successfully', _locale),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${Translations.translate('error_submitting_review', _locale)}: $e',
          ),
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextDirection textDirection = _locale == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            Translations.translate('rate_your_stay', _locale),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translations.translate('room_rating', _locale),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: roomRating,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: roomRating.toString(),
                  onChanged: (value) {
                    setState(() {
                      roomRating = value;
                    });
                  },
                ),
                Text(
                  Translations.translate('service_rating', _locale),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: serviceRating,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: serviceRating.toString(),
                  onChanged: (value) {
                    setState(() {
                      serviceRating = value;
                    });
                  },
                ),
                Text(
                  Translations.translate('overall_rating', _locale),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: overallRating,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: overallRating.toString(),
                  onChanged: (value) {
                    setState(() {
                      overallRating = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  Translations.translate('write_review', _locale),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reviewController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: Translations.translate('write_your_review_here', _locale),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 30),
                    ),
                    child: Text(
                      Translations.translate('submit_review', _locale),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}