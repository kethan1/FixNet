import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:collection/collection.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image_pixels/image_pixels.dart';
import 'package:intersperse/intersperse.dart';
import 'global.dart';

const _bigFont = TextStyle(fontSize: 24.0);
const _mediumFont = TextStyle(fontSize: 18.5);
const _mediumButBiggerFont = TextStyle(fontSize: 21.0);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixNet',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const HomePage(title: 'FixNet'),
      routes: <String, WidgetBuilder>{
        '/cart': (context) => const Cart(title: 'FixNet'),
        '/signup': (context) => const SignUp(title: 'FixNet'),
        '/login': (context) => const Login(title: 'FixNet'),
        '/library': (context) => const MyLibrary(title: 'FixNet'),
        '/search': (context) => const Search(title: 'FixNet'),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarouselController _controller = CarouselController();

  List<dynamic>? movies;
  List<dynamic>? featuredMovies;
  final ValueNotifier<int> _current = ValueNotifier<int>(0);

  Future getMovies() async {
    await MoviesData().getMovies();
    movies = MoviesData().movies;
  }

  Future getFeaturedMovies() async {
    await MoviesData().getFeaturedMovies();
    featuredMovies = MoviesData().featuredMovies;
  }

  List<Widget> getFeaturedMovieWidgets() {
    if (MoviesData().featuredMovies == null) {
      return [];
    }

    List<Widget> widgets = [];
    for (var movie in MoviesData().featuredMovies!) {
      var map = movies!.firstWhere((movieMap) => movie == movieMap['title']);
      ImageProvider imageProviderWidget =
          MoviesData().getImageProvider(map['poster'], fullSize: true);
      widgets.add(GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return MoreInfo(
              title: 'FixNet',
              itemTitle: map['title'],
              moviesInfo: map,
            );
          }));
        },
        child: Container(
          margin: const EdgeInsets.all(5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: ImagePixels(
              imageProvider: imageProviderWidget,
              defaultColor: Colors.grey,
              builder: (context, img) => SizedBox(
                width: img.hasImage ? 375 : 0,
                height: img.hasImage
                    ? min((img.width! / 375) * img.height!, 180)
                    : 0,
                child: Image(
                  image: imageProviderWidget,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      ));
    }

    return widgets;
  }

  List<Widget> getMovieWidgets() {
    List<Widget> widgets = [];

    widgets.add(const SizedBox(height: 50));

    var moviesGroupedByGenre = groupBy(movies!, (dynamic obj) => obj['genre']);

    moviesGroupedByGenre.forEach((genre, movies) {
      var moviesNotInFeatured = movies
          .where(
              (movie) => !MoviesData().featuredMovies!.contains(movie['title']))
          .toList();
      if (moviesNotInFeatured.isEmpty) {
        return;
      }

      widgets.add(Center(
        child: Text(
          genre,
          style: _bigFont,
        ),
      ));
      widgets.add(const Divider(
        height: 10,
        thickness: 2,
      ));

      List<Widget> genreMovies = [];

      for (var movie in moviesNotInFeatured) {
        ImageProvider imageProviderWidget =
            MoviesData().getImageProvider(movie['poster'], fullSize: false);
        genreMovies.add(GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return MoreInfo(
                title: 'FixNet',
                itemTitle: movie['title'],
                moviesInfo: movie,
              );
            }));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: ImagePixels(
              imageProvider: imageProviderWidget,
              defaultColor: Colors.grey,
              builder: (context, img) => SizedBox(
                width: img.hasImage ? 185 : 0,
                height: img.hasImage ? (185 / img.width!) * img.height! : 0,
                child: Image(image: imageProviderWidget, fit: BoxFit.fill),
              ),
            ),
          ),
        ));
      }

      widgets.add(SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children:
                genreMovies.intersperse(const SizedBox(width: 30)).toList(),
          ),
        ),
      ));

      widgets.add(const Divider(
        height: 10,
        thickness: 2,
      ));
    });

    widgets.add(const SizedBox(height: 15));

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        actions: [
          Container(
            child: (ModalRoute.of(context)?.canPop ?? false)
                ? const BackButton()
                : null,
          )
        ],
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Column(
                    children: const [
                      Text(
                        'Movies at a One Time Cost, Forever Accessible',
                        textAlign: TextAlign.center,
                        style: _bigFont,
                      ),
                      Text(
                        'No More Pesky Subscriptions',
                        style: _mediumFont,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: FutureBuilder(
                    future: getFeaturedMovies(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Text('Connecting...',
                                  style: _mediumButBiggerFont),
                            ],
                          );
                        case ConnectionState.waiting:
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Text('Loading...', style: _mediumButBiggerFont),
                            ],
                          );
                        default:
                          if (snapshot.hasError) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      getMovies();
                                    });
                                  },
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: const [
                                      Icon(Icons.refresh_rounded),
                                      Text('Network Error',
                                          style: _mediumButBiggerFont),
                                    ],
                                  ),
                                )
                              ],
                            );
                          } else {
                            var items = getFeaturedMovieWidgets();
                            return Column(
                              children: [
                                Expanded(
                                  child: CarouselSlider(
                                    items: items,
                                    carouselController: _controller,
                                    options: CarouselOptions(
                                      height: 300,
                                      viewportFraction: 1,
                                      enableInfiniteScroll:
                                          items.length == 1 ? false : true,
                                      autoPlay: true,
                                      autoPlayInterval:
                                          const Duration(seconds: 3),
                                      autoPlayAnimationDuration:
                                          const Duration(milliseconds: 400),
                                      enlargeCenterPage: true,
                                      onPageChanged: (index, reason) {
                                        _current.value = index;
                                      },
                                    ),
                                  ),
                                ),
                                ValueListenableBuilder<int>(
                                  valueListenable: _current,
                                  builder: (context, value, widget) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children:
                                          items.asMap().entries.map((entry) {
                                        return GestureDetector(
                                          onTap: () => _controller
                                              .animateToPage(entry.key),
                                          child: Container(
                                            width: 12.0,
                                            height: 12.0,
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 6.0, horizontal: 4.0),
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: (Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black)
                                                    .withOpacity(
                                                        value == entry.key
                                                            ? 0.9
                                                            : 0.4)),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            );
                          }
                      }
                    },
                  ),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: getMovies(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                          return const Center(
                            child: Text('Connecting...',
                                style: _mediumButBiggerFont),
                          );
                        case ConnectionState.waiting:
                          return const Center(
                            child:
                                Text('Loading...', style: _mediumButBiggerFont),
                          );
                        default:
                          if (snapshot.hasError) {
                            return Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    getMovies();
                                  });
                                },
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: const [
                                    Icon(Icons.refresh_rounded),
                                    Text('Network Error',
                                        style: _mediumButBiggerFont),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return ListView(
                              children: getMovieWidgets(),
                            );
                          }
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoreInfo extends StatefulWidget {
  const MoreInfo(
      {Key? key,
      required this.title,
      required this.itemTitle,
      required this.moviesInfo})
      : super(key: key);

  final String title;
  final String itemTitle;
  final Map<String, dynamic> moviesInfo;

  @override
  _MoreInfoState createState() => _MoreInfoState();
}

class _MoreInfoState extends State<MoreInfo> {
  Widget getRating() {
    double? averageRating;
    if (widget.moviesInfo['ratings'].length > 1) {
      averageRating = widget.moviesInfo['ratings']
              .map((e) => e['stars'])
              .toList()
              .fold(0, (a, b) => a + b) /
          widget.moviesInfo['ratings'].length;
    } else if (widget.moviesInfo['ratings'].length == 1) {
      averageRating = widget.moviesInfo['ratings'][0]['stars'];
    }

    if (averageRating == null) {
      return const Text('No Ratings Yet!', style: _mediumFont);
    } else {
      return RatingBarIndicator(
        rating: averageRating,
        direction: Axis.horizontal,
        itemCount: 5,
        itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
        itemBuilder: (context, _) => const Icon(
          Icons.star,
          color: Colors.amber,
        ),
      );
    }
  }

  Widget getImage() {
    var imageProviderWidget =
        MoviesData().getImageProvider(widget.moviesInfo['poster']);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: ImagePixels(
        imageProvider: imageProviderWidget,
        defaultColor: Colors.grey,
        builder: (context, img) => SizedBox(
          width: img.hasImage ? 250 : 0,
          height: img.hasImage ? (250 / img.width!) * img.height! : 0,
          child: Image(image: imageProviderWidget, fit: BoxFit.fill),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        actions: [
          Container(
            child: (ModalRoute.of(context)?.canPop ?? false)
                ? const BackButton()
                : null,
          )
        ],
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Center(child: Text(widget.itemTitle, style: _bigFont)),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                            onTap: () async {
                              Map<String, dynamic> response = await UserInfo()
                                  .addItemToCart(widget.itemTitle);
                              if (!response['success']) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(response['message']),
                                ));
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text('Added to Cart!'),
                                ));
                              }
                            },
                            child: Wrap(
                              children: const [
                                Text('Add to Cart', style: _mediumFont),
                                Icon(
                                  Icons.add_shopping_cart_outlined,
                                  color: Colors.black,
                                ),
                              ],
                            )),
                        const SizedBox(height: 10.0),
                        getImage(),
                        Text(widget.moviesInfo['description'],
                            style: _mediumFont, textAlign: TextAlign.center),
                        getRating(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return Reviews(
                            title: 'FixNet',
                            reviews: widget.moviesInfo['ratings'],
                            itemTitle: widget.itemTitle,
                          );
                        }));
                      },
                      child: const Text('See Reviews', style: _mediumFont),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Reviews extends StatefulWidget {
  const Reviews(
      {Key? key,
      required this.title,
      required this.reviews,
      required this.itemTitle})
      : super(key: key);

  final String title;
  final List<dynamic> reviews;
  final String itemTitle;

  @override
  _ReviewsState createState() => _ReviewsState();
}

class _ReviewsState extends State<Reviews> {
  List<Widget> getReviews() {
    List<Widget> widgetReviews = [];
    if (widget.reviews.isNotEmpty) {
      widget.reviews.forEachIndexed((index, review) {
        widgetReviews.add(
          Center(
            child: RatingBarIndicator(
              rating: review['stars'].toDouble(),
              itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
            ),
          ),
        );
        widgetReviews.add(
          Center(
              child: Text(review['description'],
                  textAlign: TextAlign.center, style: _mediumFont)),
        );
        if (index != widget.reviews.length - 1) {
          widgetReviews.add(const SizedBox(height: 70));
        }
      });
    } else {
      widgetReviews.add(
        const Center(child: Text('No Reviews Yet!', style: _mediumFont)),
      );
    }
    return widgetReviews;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        actions: [
          Container(
            child: (ModalRoute.of(context)?.canPop ?? false)
                ? const BackButton()
                : null,
          )
        ],
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      ...getReviews(),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return AddReview(
                            title: 'FixNet',
                            itemTitle: widget.itemTitle,
                          );
                        }));
                      },
                      child: const Text('Add Review', style: _mediumFont)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddReview extends StatefulWidget {
  const AddReview({Key? key, required this.title, required this.itemTitle})
      : super(key: key);

  final String title;
  final String itemTitle;

  @override
  _AddReviewState createState() => _AddReviewState();
}

class _AddReviewState extends State<AddReview> {
  final reviewController = TextEditingController();

  double rating = 0;
  Color buttonColor = Colors.blue;

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  Future<void> postReview() async {
    var name = await UserInfo().getName();
    if (rating == 0) {
      throw const UserForgot('select a rating');
    } else if (reviewController.text.isEmpty) {
      throw const UserForgot('enter a review');
    } else if (reviewController.text.length < 10) {
      throw const UserForgot('review too short');
    } else if (reviewController.text.length > 100) {
      throw const UserForgot('review too long');
    } else if (!name['success']) {
      throw UserForgot(name['message']);
    }

    var url = Uri.parse('${GlobalVars().serverUrl}/api/v1/add-review');
    var body = json.encode({
      'description':
          '${reviewController.text} - ${name['firstname']} ${name['lastname']}',
      'stars': rating,
      'movie_title': widget.itemTitle
    });

    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

    http.post(url, body: body, headers: headers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        actions: [
          Container(
            child: (ModalRoute.of(context)?.canPop ?? false)
                ? const BackButton()
                : null,
          )
        ],
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RatingBar.builder(
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                this.rating = rating;
              },
            ),
            TextField(
              controller: reviewController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your review here in 100 characters or less',
              ),
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith(
                  (states) {
                    const Set<MaterialState> interactiveStates =
                        <MaterialState>{
                      MaterialState.pressed,
                      MaterialState.hovered,
                      MaterialState.focused,
                    };
                    if (states.any(interactiveStates.contains)) {
                      return Colors.blue[300];
                    }
                    return Colors.blue;
                  },
                ),
              ),
              onPressed: () async {
                try {
                  await postReview();
                  Navigator.pushNamed(context, '/');

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sucessfully Posted Review'),
                  ));
                } on UserForgot catch (e) {
                  if (e.msg == 'select a rating') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please Select a Rating'),
                    ));
                  } else if (e.msg == 'enter a review') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please Enter a Review'),
                    ));
                  } else if (e.msg == 'review too short') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please Enter a Longer Review'),
                    ));
                  } else if (e.msg == 'review too long') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please Enter a Shorter Review'),
                    ));
                  } else if (e.msg == 'Not logged in') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Please Login or Sign Up Before Posting a Review'),
                    ));
                  } else if (e.msg == 'Server timed out') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Server Timed Out. Try Again'),
                    ));
                  } else if (e.msg == 'User Not Found') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('User Not Found'),
                    ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('An Error Occurred'),
                    ));
                  }
                }
              },
              child: const Text('Publish Your Review', style: _mediumFont),
            ),
          ],
        ),
      ),
    );
  }
}

class Cart extends StatefulWidget {
  const Cart({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  List<String>? itemsInCart;

  Future<void> getItems() async {
    Map<String, dynamic> cartItems = await UserInfo().getCartItems();
    if (cartItems['success']) {
      itemsInCart = cartItems['items'];
    } else {
      if (cartItems['message']! == 'Server timed out') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Server Timed Out'),
        ));
      }
    }
  }

  List<Widget> getWidgetItems() {
    List<Widget> widgets = [];
    Map<String, Map<dynamic, dynamic>> titleToIndex = {};
    for (var map in MoviesData().movies!) {
      titleToIndex[map['title']] = map;
    }
    if (itemsInCart != null && itemsInCart!.isNotEmpty) {
      List<double> prices = [];
      for (String item in itemsInCart!) {
        widgets.add(Row(
          children: [
            Expanded(
              flex: 3,
              child: MoviesData().getImage(
                titleToIndex[item]!['poster'],
                fullSize: false,
              ),
            ),
            const Spacer(flex: 1),
            Expanded(
              flex: 8,
              child: Text(item, style: _bigFont),
            ),
            Expanded(
              flex: 4,
              child: Text('\$${titleToIndex[item]!['cost']}', style: _bigFont),
            ),
          ],
        ));
        prices.add(titleToIndex[item]!['cost']);
      }
      double totalPrice = double.parse(prices.sum.toStringAsFixed(2));
      widgets.add(const Divider(
        height: 40,
        thickness: 5,
      ));
      widgets.add(Row(children: [
        const Expanded(
          flex: 3,
          child: Text('Total Cost', style: _bigFont),
        ),
        Expanded(
          flex: 1,
          child: Text('\$$totalPrice', style: _bigFont),
        ),
        const Divider(
          height: 40,
          thickness: 0,
        ),
      ]));
      widgets.add(Container(
        margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 40.0),
        child: ElevatedButton(
          onPressed: () async {
            for (String item in itemsInCart!) {
              await UserInfo().removeItemFromCart(item);
              await UserInfo().addItemToLibrary(item);
            }
            Navigator.pushNamed(context, '/');
          },
          child: const Text(
            'Checkout',
            style: _mediumFont,
          ),
        ),
      ));
    } else {
      widgets
          .add(const Center(child: Text('No Items in Cart', style: _bigFont)));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        actions: [
          Container(
            child: (ModalRoute.of(context)?.canPop ?? false)
                ? const BackButton()
                : null,
          )
        ],
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FutureBuilder(
            future: getItems(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Center(
                          child:
                              Text('Loading...', style: _mediumButBiggerFont)),
                    ],
                  );
                case ConnectionState.waiting:
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Center(
                          child:
                              Text('Loading...', style: _mediumButBiggerFont)),
                    ],
                  );
                default:
                  if (snapshot.hasError) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await getItems();
                            setState(() {});
                          },
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: const [
                              Text('Unable to load cart. Tap to retry.',
                                  style: _mediumButBiggerFont),
                              Icon(Icons.refresh_rounded),
                            ],
                          ),
                        )
                      ],
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ListView(
                        shrinkWrap: true,
                        children: getWidgetItems(),
                      ),
                    );
                  }
              }
            },
          ),
        ],
      ),
    );
  }
}

class SignUp extends StatefulWidget {
  const SignUp({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void signup() async {
    if (firstName.text.isEmpty ||
        lastName.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields'),
      ));
    } else if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Confirm Password Does Not Match Password'),
      ));
    } else {
      Map<String, dynamic> signupResponse = await UserInfo()
          .signup(firstName.text, lastName.text, email.text, password.text);
      if (signupResponse['success']!) {
        Navigator.pushNamed(context, '/');
      } else {
        if (signupResponse['message']! == 'User Already Exists') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Account with That Email Already Exists'),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could Not Connect to the Server'),
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        actions: [
          Container(
            child: (ModalRoute.of(context)?.canPop ?? false)
                ? const BackButton()
                : null,
          )
        ],
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 25.0),
        child: Column(
          children: [
            const Text('Signup', style: _bigFont),
            const Spacer(flex: 23),
            TextField(
              controller: firstName,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            const Spacer(),
            TextField(
              controller: lastName,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            const Spacer(),
            TextField(
              controller: email,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            const Spacer(),
            TextField(
              controller: password,
              enableSuggestions: false,
              autocorrect: false,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            const Spacer(),
            TextField(
              controller: confirmPassword,
              enableSuggestions: false,
              autocorrect: false,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Comfirm Password',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => signup(),
              child: const Text(
                'Sign Up',
                style: _mediumFont,
              ),
            ),
            const Spacer(flex: 28),
          ],
        ),
      ),
    );
  }
}

class Login extends StatefulWidget {
  const Login({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void login() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields'),
      ));
    } else {
      Map<String, dynamic> loginResponse =
          await UserInfo().login(email.text, password.text);
      if (loginResponse['success']!) {
        Navigator.pushNamed(context, '/');
      } else {
        if (loginResponse['message']!.toString() == 'Invalid credentials') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Invalid Email or Password'),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could Not Connect to the Server'),
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        actions: [
          Container(
            child: (ModalRoute.of(context)?.canPop ?? false)
                ? const BackButton()
                : null,
          )
        ],
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Login', style: _bigFont),
            const Spacer(flex: 55),
            TextField(
              controller: email,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            const Spacer(),
            TextField(
              controller: password,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => login(),
              child: const Text(
                'Login',
                style: _mediumFont,
              ),
            ),
            const Spacer(flex: 65),
          ],
        ),
      ),
    );
  }
}

class MyLibrary extends StatefulWidget {
  const MyLibrary({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyLibraryState createState() => _MyLibraryState();
}

class _MyLibraryState extends State<MyLibrary> {
  List<String> myLibrary = [];

  Future<void> getLibrary() async {
    Map<String, dynamic> libraryItemsResponse =
        await UserInfo().getLibraryItems();
    if (libraryItemsResponse['success']) {
      myLibrary = libraryItemsResponse['items'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could Not Connect to the Server', style: _mediumFont),
      ));
    }
  }

  List<Widget> libraryLayout() {
    List<Widget> widgets = [];
    Map<String, Map<dynamic, dynamic>> titleToIndex = {};
    for (var map in MoviesData().movies!) {
      titleToIndex[map['title']] = map;
    }
    if (myLibrary.isNotEmpty) {
      for (String item in myLibrary) {
        widgets.add(Row(
          children: [
            Expanded(
              flex: 3,
              child: MoviesData().getImage(
                titleToIndex[item]!['poster'],
                fullSize: true,
              ),
            ),
            const Spacer(flex: 1),
            Expanded(
              flex: 8,
              child: Text(item, style: _bigFont),
            ),
            const Spacer(flex: 1),
            TextButton(
              onPressed: () {
                // redirect to movie page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WatchMovie(title: widget.title, movieTitle: item),
                  ),
                );
              },
              child: const Text('Watch', style: _mediumFont),
            ),
          ],
        ));
      }
    } else {
      widgets.add(
        const Center(child: Text('No Items in Library', style: _bigFont)),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        actions: [
          Container(
            child: (ModalRoute.of(context)?.canPop ?? false)
                ? const BackButton()
                : null,
          )
        ],
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: FutureBuilder(
                future: getLibrary(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                      return const Text('No Connection', style: _mediumFont);
                    case ConnectionState.waiting:
                      return const Center(child: CircularProgressIndicator());
                    case ConnectionState.active:
                      return const Center(child: CircularProgressIndicator());
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return GestureDetector(
                          onTap: () async {
                            await getLibrary();
                            setState(() {});
                          },
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: const [
                              Text('Unable to load movies. Tap to retry.',
                                  style: _mediumButBiggerFont),
                              Icon(Icons.refresh_rounded),
                            ],
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: ListView(
                              shrinkWrap: true, children: libraryLayout()),
                        );
                      }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WatchMovie extends StatefulWidget {
  const WatchMovie({Key? key, required this.title, required this.movieTitle})
      : super(key: key);

  final String title;
  final String movieTitle;

  @override
  _WatchMovieState createState() => _WatchMovieState();
}

class _WatchMovieState extends State<WatchMovie> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool controllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(GlobalVars().serverUrl +
        '/api/v1/stream-movie/' +
        widget.movieTitle.toLowerCase().replaceAll(' ', '_'));
    _controller!.initialize().then((_) {
      setState(() {
        _chewieController =
            ChewieController(videoPlayerController: _controller!);
        controllerInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        actions: [
          Container(
            child: (ModalRoute.of(context)?.canPop ?? false)
                ? const BackButton()
                : null,
          )
        ],
        title: Text(widget.title),
      ),
      body: Center(
        child: controllerInitialized
            ? Chewie(controller: _chewieController!)
            : Container(),
      ),
    );
  }

  @override
  void dispose() {
    print(_chewieController);
    _controller!.dispose();
    _chewieController!.dispose();
    super.dispose();
  }
}

class Search extends StatefulWidget {
  const Search({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final ValueNotifier<List<dynamic>> moviesFound = ValueNotifier([]);

  void search(String searchTerm) {
    moviesFound.value = MoviesData()
        .movies!
        .where((item) =>
            item['title'].toLowerCase().contains(searchTerm) &&
            searchTerm.isNotEmpty)
        .toList();
  }

  List<Widget> getSearchWidgets() {
    List<Widget> widgets = [];
    for (var movie in moviesFound.value) {
      ImageProvider imageProviderWidget =
          MoviesData().getImageProvider(movie['poster'], fullSize: false);
      widgets.add(GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return MoreInfo(
              title: 'FixNet',
              itemTitle: movie['title'],
              moviesInfo: movie,
            );
          }));
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Image(image: imageProviderWidget),
        ),
      ));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        actions: [
          Container(
            child: (ModalRoute.of(context)?.canPop ?? false)
                ? const BackButton()
                : null,
          )
        ],
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SearchWidget(onChange: search),
            const SizedBox(height: 20),
            ValueListenableBuilder<List<dynamic>>(
              valueListenable: moviesFound,
              builder: (context, value, widget) {
                if (value.isEmpty) {
                  return const Text('No Movies Found', style: _mediumFont);
                } else {
                  return Expanded(
                    child: GridView.count(
                      childAspectRatio: MediaQuery.of(context).size.width /
                          (MediaQuery.of(context).size.height / 1.45),
                      mainAxisSpacing: 5,
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      children: getSearchWidgets(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SearchWidget extends StatefulWidget {
  const SearchWidget({Key? key, this.onChange = onChangePlaceholder})
      : super(key: key);

  final void Function(String) onChange;
  static onChangePlaceholder(String _) {}

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final FocusNode _focus = FocusNode();

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: widget.onChange,
      controller: _controller,
      focusNode: _focus,
      decoration: InputDecoration(
        labelText: 'Search',
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 1.0),
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Colors.grey,
        ),
        suffixIcon: GestureDetector(
          onTap: () {
            _controller.clear();
            _focus.unfocus();
          },
          child: const Icon(
            Icons.close,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  String getValue() => _controller.text;
}

class UserForgot implements Exception {
  final String msg;
  const UserForgot(this.msg);

  @override
  String toString() => 'UserForgot: $msg';
}
