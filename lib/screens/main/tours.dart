import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guidely/blocs/main/tours_bloc.dart' as toursBloc;
import 'package:guidely/blocs/main/tours_bloc.dart';
import 'package:guidely/misc/common.dart';
import 'package:guidely/models/data/quiz/quiz_item.dart';
import 'package:guidely/models/entities/tour.dart' as toursModel;
import 'package:guidely/models/entities/tour.dart';
import 'package:guidely/models/entities/user.dart';
import 'package:guidely/models/enums/tour_guide_auth_state.dart';
import 'package:guidely/providers/tours_provider.dart';
import 'package:guidely/providers/user_data_provider.dart';
import 'package:guidely/screens/secondary/tour_details.dart';
import 'package:guidely/screens/session/tour_session.dart';
import 'package:guidely/screens/util/quiz_creator/quiz_creator_screen.dart';
import 'package:guidely/screens/util/review_creator/review_creator_screen.dart';
import 'package:guidely/screens/util/tour_creation/tour_creator.dart';
import 'package:guidely/screens/util/waitingforhost.dart';
import 'package:guidely/utils/util.dart';
import 'package:guidely/widgets/customs/custom_text_field.dart';
import 'package:guidely/widgets/entities/tour_list_item/tour_list_item.dart';

class ToursScreen extends ConsumerStatefulWidget {
  const ToursScreen({super.key});

  @override
  _ToursScreenState createState() => _ToursScreenState();
}

class _ToursScreenState extends ConsumerState<ToursScreen> {
  final TourBloc _tourBloc = toursBloc.TourBloc();
  User? _userData;
  List<QuizItem> quizItems = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tourBloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);
    final tourDataAsync = ref.watch(toursStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tours',
          style: poppinsFont.copyWith(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: userDataAsync.maybeWhen(
          data: (userData) {
            if (userData.authState == TourGuideAuthState.authenticated) {
              _userData = userData;
              return [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TourCreatorScreen(),
                      ),
                    );
                    // re-render the screen after the user has created a tour
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.quiz),
                  onPressed: () {
                    _showQuizDialog(context, userData.organizedTours);
                  },
                ),
              ];
            }
            return null;
          },
          orElse: () {
            return null;
          },
        ),
      ),
      body: userDataAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
        data: (userData) {
          // Assign _userData when data is available
          _userData = userData;
          return tourDataAsync.when(
            data: (tours) {
              _tourBloc.loadTours(userData, tours);
              return StreamBuilder<toursBloc.TourState>(
                stream: _tourBloc.state,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.connectionState ==
                      ConnectionState.active) {
                    final state = snapshot.data;
                    if (state is toursBloc.ToursLoaded) {
                      return DefaultTabController(
                        length: 3,
                        child: Scaffold(
                          appBar: const TabBar(
                            tabs: [
                              Tab(text: 'Past'),
                              Tab(text: 'Live now'),
                              Tab(text: 'Upcoming'),
                            ],
                          ),
                          body: TabBarView(
                            children: [
                              _buildTourList(
                                  state.pastTours, _buildPastActions, false),
                              _buildTourList(
                                  state.liveTours, _buildLiveActions, true),
                              _buildTourList(state.upcomingTours,
                                  _buildUpcomingActions, true),
                            ],
                          ),
                        ),
                      );
                    } else if (state is toursBloc.TourError) {
                      return Center(child: Text('Error: ${state.error}'));
                    }
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text('Error: $error'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTourList(
      List<Tour> tours, actionBuilder, bool displayRemainingTime) {
    return tours.isEmpty
        ? Center(
            child: Text(
              'No tours available',
              style: poppinsFont.copyWith(fontSize: 15),
            ),
          )
        : ListView.builder(
            itemCount: tours.length,
            itemBuilder: (BuildContext context, int index) {
              final tour = tours[index];
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    TourListItem(
                      tour: tour,
                      displayRemainingTime: displayRemainingTime,
                    ),
                    Row(
                      children: actionBuilder(tour),
                    ),
                  ],
                ),
              );
            },
          );
  }

  List<Widget> _buildUpcomingActions(Tour tour) {
    final isAHoster = _userData?.organizedTours.contains(tour.uid) ?? false;

    return [
      isAHoster
          ? OutlinedButton(
              onPressed: () {
                // define a controller for the announcement
                final announcementController = TextEditingController();
                // ask user to announce the tour
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Announce Tour'),
                      content: Column(
                        children: [
                          const Text('You can announce the tour here:'),
                          const SizedBox(height: 10),
                          CustomTextField(
                              controller: announcementController,
                              header: 'Announcement'),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Announce'),
                          onPressed: () {
                            _tourBloc.announceTour(
                                tour, announcementController.text);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Announce'),
            )
          : const SizedBox(),
      const SizedBox(width: 5),
      OutlinedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TourDetailsScreen(tour: tour),
            ),
          );
        },
        child: const Text('Get Info'),
      ),
      const SizedBox(width: 5),
      isAHoster
          ? TextButton(
              onPressed: () {
                // ask user to cancel the tour
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Cancel Tour'),
                      content: const Text('Do you want to cancel the tour?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Cancel Tour'),
                          onPressed: () {
                            _tourBloc.cancelTour(tour, context);
                            Navigator.of(context).pop();
                            setState(() {});
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text('Cancel'),
            )
          : const SizedBox(),
    ];
  }

  List<Widget> _buildLiveActions(Tour tour) {
    final isAHoster = _userData?.organizedTours.contains(tour.uid) ?? false;
    final tourHasStarted = tour.state == toursModel.TourState.live;

    return [
      OutlinedButton(
        onPressed: () {
          // If the user is a hoster, ask him to start the tour
          if (isAHoster && !tourHasStarted) {
            // Start the tour
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Start Tour'),
                  content: const Text('Do you want to start the tour?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Start'),
                      onPressed: () {
                        _tourBloc.startTour(tour);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TourSessionScreen(
                              tour: tour,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => tourHasStarted
                    ? TourSessionScreen(
                        tour: tour,
                      )
                    : WaitingForHostScreen(
                        tour: tour,
                      ),
              ),
            );
          }
        },
        child: Text(isAHoster ? 'Start Session' : 'Join Now'),
      ),
      const SizedBox(width: 5),
      OutlinedButton(
        onPressed: () {
          final startingLocationWaypoints = tour.tourDetails.startingLocation;
          // open google maps with the starting location
          openGoogleMaps(
            startingLocationWaypoints.latitude,
            startingLocationWaypoints.longitude,
          );
        },
        child: const Text('Get Directions'),
      ),
    ];
  }

  List<Widget> _buildPastActions(Tour tour) {
    final userHasReviewed =
        tour.reviews.any((review) => review.uid == _userData?.uid);
    final organizedByUser = _userData?.uid == tour.organizer.uid;
    return [
      ElevatedButton(
        onPressed: userHasReviewed || organizedByUser
            ? () {} // No action when user has reviewed
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return ReviewCreatorScreen(
                        tour: tour,
                        userData: _userData!,
                      );
                    },
                  ),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              userHasReviewed || organizedByUser ? Colors.green : Colors.grey,
        ),
        child: Text(
          organizedByUser
              ? 'Your Tour'
              : userHasReviewed
                  ? 'Reviewed'
                  : 'Review',
          style: TextStyle(
            color: userHasReviewed || organizedByUser
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    ];
  }

  void _showQuizDialog(BuildContext context, List<String> organizedTours) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Tour'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: organizedTours.map((tourId) {
                return FutureBuilder<Tour?>(
                  future: _fetchTourDetails(tourId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('Loading...'),
                      );
                    } else if (snapshot.hasError) {
                      return ListTile(
                        title: Text('Error: ${snapshot.error}'),
                      );
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return const ListTile(
                        title: Text('Tour not found'),
                      );
                    } else {
                      final tour = snapshot.data!;
                      return ListTile(
                        title: Text(tour.tourDetails.title),
                        onTap: () {
                          Navigator.of(context).pop(); // Close the dialog
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => QuizCreatorScreen(
                                tour: tour,
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Tour?> _fetchTourDetails(String tourId) async {
    try {
      // Fetch the document snapshot from Firestore
      DocumentSnapshot tourDoc = await FirebaseFirestore.instance
          .collection('tours')
          .doc(tourId)
          .get();

      // Check if the document exists
      if (tourDoc.exists) {
        // Create a Tour object from the Firestore data
        return Tour.fromMap(tourDoc.data() as Map<String, dynamic>);
      } else {
        // Log the error and return null if the document does not exist
        print('Tour with ID $tourId not found.');
        return null;
      }
    } catch (e) {
      // Log any errors that occur during the fetch operation
      print('Error fetching tour: $e');
      return null;
    }
  }
}
