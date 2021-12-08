import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import "dart:convert";
import "package:flutter_rating_bar/flutter_rating_bar.dart";

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
      home: const HomePageAndShop(title: 'FixNet'),
      routes: <String, WidgetBuilder>{
        "/cart": (BuildContext context) => Cart(title: "FixNet"),
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

  getMovies() async {
    var url = Uri.parse("http://10.0.2.2:5000/api/v1/get_movies");
    var response = http.get(url);
    response.then((value) {
      if (value.statusCode == 200) {
        movies = jsonDecode(value.body);
      } else {
        throw Exception("Failed to retrieve scores");
      }
    });
  }

  List<Widget> getMovieWidgets() {
    List<Widget> widgets = [];
    if (movies != null) {
      widgets.add(
        const Divider(
          height: 50,
          thickness: 0,
          color: Color.fromRGBO(255, 255, 255, 1.0),
        ),
      );

      movies!.asMap().forEach((index, movie) {
        Widget imageWidget;
        if (movie["preview_pic"].startsWith("data:image")) {
          imageWidget = Image.memory(
            base64Decode(movie["preview_pic"].split(",").last),
          );
        } else {
          imageWidget = Image.network(movie["preview_pic"]);
        }
        widgets.add(GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return MoreInfo(
                title: "FixNet",
                itemTitle: movie["title"],
                moviesInfo: movie,
              );
            }));
            print("$movie clicked");
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
    getMovies();
    return Scaffold(
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
                        'Movies At a One Time Cost, Forever Accessible',
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: getMovieWidgets(),
                        ),
                      ),
                    ],
                  ),
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    children: [
                      Center(
                        child: Text(widget.itemTitle, style: _bigFont),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        urlToImgObj(widget.moviesInfo["preview_pic"]),
                        Text(widget.moviesInfo["description"],
                            style: _mediumFont, textAlign: TextAlign.center),
                        RatingBar.builder(
                          initialRating: 3,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            print(rating);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  List<String> _inCart = [];

  @override
  Widget build(BuildContext context) {
    return Column();
  }
}
