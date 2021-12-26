import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "dart:convert";
import "package:flutter_rating_bar/flutter_rating_bar.dart";
import "package:collection/collection.dart";
import "global.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "FixNet",
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const HomePageAndShop(title: "FixNet"),
      routes: <String, WidgetBuilder>{
        "/cart": (context) => const Cart(title: "FixNet"),
        "/signup": (context) => const SignUp(title: "FixNet"),
        "/login": (context) => const Login(title: "FixNet"),
      },
    );
  }
}

class HomePageAndShop extends StatefulWidget {
  const HomePageAndShop({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageAndShopState createState() => _HomePageAndShopState();
}

class _HomePageAndShopState extends State<HomePageAndShop> {
  static const _bigFont = TextStyle(fontSize: 24.0);
  static const _mediumFont = TextStyle(fontSize: 18.5);
  static const _mediumButBiggerFont = TextStyle(fontSize: 21.0);

  List<dynamic>? movies;

  Future getMovies() async {
    var url = Uri.parse("${GlobalVars().serverUrl}/api/v1/get_movies");
    var response = await http.get(url).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      movies = json.decode(response.body);
      MoviesData().setMovies(movies!);
    }
  }

  List<Widget> getMovieWidgets() {
    List<Widget> widgets = [];
    if (movies != null) {
      widgets.add(
        const Divider(
          height: 50,
          thickness: 0,
          color: Colors.white,
        ),
      );

      movies!.asMap().forEach((index, movie) {
        Widget imageWidget = MoviesData().getImage(movie["preview_pic"]);
        widgets.add(GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return MoreInfo(
                title: "FixNet",
                itemTitle: movie["title"],
                moviesInfo: movie,
              );
            }));
          },
          child: Column(
            children: [
              Text(movie["title"] + "\n", style: _mediumButBiggerFont),
              imageWidget,
            ],
          ),
        ));
        if (index != movies!.length - 1) {
          widgets.add(
            const Divider(
              height: 50,
              thickness: 5,
            ),
          );
        }
      });

      widgets.add(
        const Divider(
          height: 15,
          thickness: 0,
          color: Color.fromRGBO(255, 255, 255, 1.0),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
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
                        "Movies At a One Time Cost, Forever Accessible",
                        textAlign: TextAlign.center,
                        style: _bigFont,
                      ),
                      Text(
                        "No More Pesky Subscriptions",
                        style: _mediumFont,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: FutureBuilder(
                    future: getMovies(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Text("Connecting...",
                                  style: _mediumButBiggerFont),
                            ],
                          );
                        case ConnectionState.waiting:
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Text("Loading...", style: _mediumButBiggerFont),
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
                                    getMovies();
                                    setState(() {});
                                  },
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: const [
                                      Icon(Icons.refresh_rounded),
                                      Text("Network Error",
                                          style: _mediumButBiggerFont),
                                    ],
                                  ),
                                )
                              ],
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
  static const _bigFont = TextStyle(fontSize: 24.0);
  static const _mediumFont = TextStyle(fontSize: 18.5);
  static const _mediumButBiggerFont = TextStyle(fontSize: 21.0);

  Widget urlToImgObj(url) {
    if (url.startsWith("data:image")) {
      return Image.memory(
        base64Decode(url.split(",").last),
      );
    } else {
      return Image.network(url);
    }
  }

  Widget getRating() {
    double? averageRating;
    if (widget.moviesInfo["ratings"].length > 1) {
      averageRating = widget.moviesInfo["ratings"]
              .map((e) => e["stars"])
              .toList()
              .fold(0, (a, b) => a + b) /
          widget.moviesInfo["ratings"].length;
    } else if (widget.moviesInfo["ratings"].length == 1) {
      averageRating = widget.moviesInfo["ratings"][0]["stars"];
    }

    if (averageRating == null) {
      return const Text("No Ratings Yet!", style: _mediumFont);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0),
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  Align(child: Text(widget.itemTitle, style: _bigFont)),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                        onTap: () async {
                          Map<String, dynamic> response =
                              await UserInfo().addItemToCart(widget.itemTitle);
                          if (!response["success"]) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(response["message"]),
                            ));
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("Added to Cart!"),
                            ));
                          }
                        },
                        child: const Text("Add to Cart", style: _mediumFont)),
                  )
                ],
              ),
            ),
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
                        urlToImgObj(widget.moviesInfo["preview_pic"]),
                        Text(widget.moviesInfo["description"],
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
                            title: "FixNet",
                            reviews: widget.moviesInfo["ratings"],
                            itemTitle: widget.itemTitle,
                          );
                        }));
                      },
                      child: const Text("See Reviews", style: _mediumFont),
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
  static const _bigFont = TextStyle(fontSize: 24.0);
  static const _mediumFont = TextStyle(fontSize: 18.5);
  static const _mediumButBiggerFont = TextStyle(fontSize: 21.0);

  List<Widget> getReviews() {
    List<Widget> widgetReviews = [];
    widget.reviews.forEachIndexed((index, review) {
      widgetReviews.add(
        Center(
          child: RatingBarIndicator(
            rating: review["stars"].toDouble(),
            itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
          ),
        ),
      );
      widgetReviews.add(
        Center(child: Text(review["description"], style: _mediumFont)),
      );
      if (index != widget.reviews.length - 1) {
        widgetReviews
            .add(const Divider(height: 70, thickness: 0, color: Colors.white));
      }
    });
    return widgetReviews;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
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
            )),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return AddReview(
                          title: "FixNet",
                          itemTitle: widget.itemTitle,
                        );
                      }));
                    },
                    child: const Text("Add Review", style: _mediumFont)),
              ],
            ),
          ],
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
  final myController = TextEditingController();
  static const _bigFont = TextStyle(fontSize: 24.0);
  static const _mediumFont = TextStyle(fontSize: 18.5);
  static const _mediumButBiggerFont = TextStyle(fontSize: 21.0);

  double rating = 0;

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    myController.dispose();
    super.dispose();
  }

  void postReview() {
    if (rating == 0) {
      throw const UserForgot("select a rating");
    }
    var url = Uri.parse("${GlobalVars().serverUrl}/api/v1/add_review");
    var body = json.encode({
      "description": myController.text,
      "stars": rating,
      "movie_title": widget.itemTitle
    });

    Map<String, String> headers = {
      "Content-type": "application/json",
      "Accept": "application/json",
    };

    http.post(url, body: body, headers: headers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(children: [
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
            controller: myController,
            maxLength: 100,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter your review here in 100 characters or less",
            ),
          ),
          TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
            ),
            onPressed: () {
              try {} on UserForgot catch (e) {
                if (e.msg == "select a rating") {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Please Select a Rating"),
                  ));
                }
              }
              postReview();
            },
            child: const Text("Publish Your Review", style: _mediumFont),
          )
        ]),
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
  static const _bigFont = TextStyle(fontSize: 24.0);
  static const _mediumFont = TextStyle(fontSize: 18.5);
  static const _mediumButBiggerFont = TextStyle(fontSize: 21.0);

  Future<void> getItems() async {
    Map<String, dynamic> cartItems = await UserInfo().getCartItems();
    if (cartItems["success"]) {
      itemsInCart = cartItems["items"];
    } else {
      if (cartItems["message"]! == "Server timed out") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Server Timed Out"),
        ));
      }
    }
  }

  List<Widget> getWidgetItems() {
    List<Widget> widgets = [];
    Map<String, Map<dynamic, dynamic>> titleToIndex = {};
    for (var map in MoviesData().movies!) {
      titleToIndex[map["title"]] = map;
    }
    if (itemsInCart != null && itemsInCart!.isNotEmpty) {
      List<double> prices = [];
      for (String item in itemsInCart!) {
        widgets.add(Row(
          children: [
            Expanded(
                flex: 3,
                child:
                    MoviesData().getImage(titleToIndex[item]!["preview_pic"])),
            const Spacer(flex: 1),
            Expanded(
              flex: 8,
              child: Text(item, style: _bigFont),
            ),
            Expanded(
              flex: 4,
              child: Text("\$${titleToIndex[item]!['cost']}", style: _bigFont),
            ),
          ],
        ));
        prices.add(titleToIndex[item]!['cost']);
      }
      double totalPrice = prices.sum / prices.length;
      widgets.add(const Divider(
        height: 40,
        thickness: 5,
      ));
      widgets.add(Row(children: [
        const Expanded(
          flex: 3,
          child: Text("Total Cost", style: _bigFont),
        ),
        Expanded(
          flex: 1,
          child: Text("\$$totalPrice", style: _bigFont),
        ),
        const Divider(
          height: 40,
          thickness: 0,
        ),
      ]));
      widgets.add(Container(
        margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 40.0),
        child: ElevatedButton(
          onPressed: () {},
          child: const Text(
            'Checkout',
            style: _mediumFont,
          ),
        ),
      ));
    } else {
      widgets
          .add(const Center(child: Text("No Items in Cart", style: _bigFont)));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
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
                      Text("Loading...", style: _mediumButBiggerFont),
                    ],
                  );
                case ConnectionState.waiting:
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text("Loading...", style: _mediumButBiggerFont),
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
                            getItems();
                            setState(() {});
                          },
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: const [
                              Text("Unable to load cart items. Tap to retry.",
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
  static const _bigFont = TextStyle(fontSize: 24.0);
  static const _mediumFont = TextStyle(fontSize: 18.5);
  static const _mediumButBiggerFont = TextStyle(fontSize: 21.0);

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
        content: Text("Please fill in all fields"),
      ));
    } else if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Confirm Password Does Not Match Password"),
      ));
    } else {
      Map<String, dynamic> signupResponse = await UserInfo()
          .signup(firstName.text, lastName.text, email.text, password.text);
      if (signupResponse["success"]!) {
        Navigator.pushNamed(context, "/");
      } else {
        if (signupResponse["message"]! == "User Already Exists") {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Account with That Email Already Exists"),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Could Not Connect to the Server"),
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
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 25.0),
        child: Column(
          children: [
            const Text("Signup", style: _bigFont),
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
  static const _bigFont = TextStyle(fontSize: 24.0);
  static const _mediumFont = TextStyle(fontSize: 18.5);
  static const _mediumButBiggerFont = TextStyle(fontSize: 21.0);

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void login() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please fill in all fields"),
      ));
    } else {
      Map<String, dynamic> loginResponse =
          await UserInfo().login(email.text, password.text);
      if (loginResponse["success"]!) {
        Navigator.pushNamed(context, "/");
      } else {
        if (loginResponse["message"]!.toString() == "Invalid credentials") {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Invalid Email or Password"),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Could Not Connect to the Server"),
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
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Login", style: _bigFont),
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
  static const _bigFont = TextStyle(fontSize: 24.0);
  static const _mediumFont = TextStyle(fontSize: 18.5);
  static const _mediumButBiggerFont = TextStyle(fontSize: 21.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalVars().drawer(context, bigFont: _bigFont),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          
        ]
      )
    );
  }
}

class UserForgot implements Exception {
  final String msg;
  const UserForgot(this.msg);

  @override
  String toString() => "UserForgot: $msg";
}
