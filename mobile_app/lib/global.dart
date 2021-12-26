import 'dart:async';

import "package:flutter/foundation.dart" show kIsWeb;
import "package:shared_preferences/shared_preferences.dart";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "dart:convert";

class GlobalVars {
  bool debug = true;
  late String serverUrl = debug
      ? (kIsWeb ? "http://localhost:5000" : "http://10.0.2.2:5000")
      : "http://10.0.2.2:5000";

  static final GlobalVars _singleton = GlobalVars._internal();

  factory GlobalVars() {
    return _singleton;
  }

  Widget drawer(BuildContext context,
      {TextStyle bigFont = const TextStyle(fontSize: 21.0)}) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.red,
            ),
            child: Text("Pages", style: bigFont),
          ),
          ListTile(
            title: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.home),
                Text(" Home", style: bigFont),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(context, "/");
            },
          ),
          if (UserInfo().signedIn)
            ListTile(
              title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart),
                  Text(" Cart", style: bigFont),
                ],
              ),
              onTap: () => Navigator.pushNamed(context, "/cart"),
            ),
          if (!UserInfo().initialized || !UserInfo().signedIn)
            ListTile(
              title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.home),
                  Text(" Sign Up", style: bigFont),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(context, "/signup");
              },
            ),
          if (!UserInfo().initialized || !UserInfo().signedIn)
            ListTile(
              title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.home),
                  Text(" Login", style: bigFont),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(context, "/login");
              },
            ),
          if (UserInfo().signedIn)
            ListTile(
              title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.home),
                  Text(" Logout", style: bigFont),
                ],
              ),
              onTap: () {
                UserInfo().logout();
                Navigator.pushNamed(context, "/");
              },
            ),
        ],
      ),
    );
  }

  GlobalVars._internal();
}

class MoviesData {
  List<dynamic>? movies;

  static final MoviesData _singleton = MoviesData._internal();

  factory MoviesData() {
    return _singleton;
  }

  setMovies(List<dynamic> movies) {
    this.movies = movies;
  }

  Widget getImage(String image) {
    if (image.startsWith("data:image")) {
      return Image.memory(
        base64Decode(image.split(",").last),
      );
    } else {
      return Image.network(image);
    }
  }

  MoviesData._internal();
}

class UserInfo {
  List<String> userCredentials = [];
  dynamic prefs;
  bool initialized = false;
  Future? _doneFuture;
  bool signedIn = false;

  init() async {
    if (!initialized) {
      prefs = await SharedPreferences.getInstance();
      if (prefs.getStringList("usercredentials") == null) {
        prefs.setStringList("usercredentials", <String>[]);
      } else {
        userCredentials =
            List<String>.from(prefs.getStringList("usercredentials")!);
      }
      initialized = true;
    }
  }

  static final UserInfo _singleton = UserInfo._internal();

  factory UserInfo() {
    _singleton._doneFuture = _singleton.init();
    return _singleton;
  }

  UserInfo._internal();

  Future<Map<String, dynamic>> login(String email, String password) async {
    if (!initialized) {
      await _doneFuture;
    }
    var body = json.encode({
      "email": email,
      "password": password,
    });

    Map<String, String> headers = {
      "Content-type": "application/json",
      "Accept": "application/json",
    };
    http.Response response;
    try {
      response = await http
          .post(Uri.parse(GlobalVars().serverUrl + "/api/v1/login"),
              body: body, headers: headers)
          .timeout(const Duration(seconds: 5));
    } on TimeoutException catch(e) {
      return {"success": false, "message": "Server timed out"};
    }

    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      if (body["success"]) {
        userCredentials = [email, password];
        prefs.setStringList("usercredentials", userCredentials);
        signedIn = true;
        return {"success": true};
      }
    }
    return {"success": false, "message": "Invalid credentials"};
  }

  Future<Map<String, dynamic>> signup(
      String firstname, String lastname, String email, String password) async {
    if (!initialized) {
      await _doneFuture;
    }
    var body = json.encode({
      "firstname": firstname,
      "lastname": lastname,
      "email": email,
      "password": password,
    });

    Map<String, String> headers = {
      "Content-type": "application/json",
      "Accept": "application/json",
    };
    http.Response response;
    try {
      response = await http
          .post(Uri.parse(GlobalVars().serverUrl + "/api/v1/signup"),
              body: body, headers: headers)
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      return {"success": false, "message": "Server timed out"};
    }
    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      if (body["success"]) {
        userCredentials = [email, password];
        prefs.setStringList("usercredentials", userCredentials);
        signedIn = true;
        return {"success": true};
      }
    }
    return {"success": false, "message": "User already exists"};
  }

  void logout() async {
    if (!initialized) {
      await _doneFuture;
    }
    userCredentials = [];
    signedIn = false;
    prefs.setStringList("usercredentials", userCredentials);
  }

  Future<Map<String, dynamic>> getCartItems() async {
    if (!initialized) {
      await _doneFuture;
    }

    if (userCredentials.length != 2) {
      return {"success": false, "message": "Not logged in"};
    }

    var body = json.encode({
      "email": userCredentials[0],
      "password": userCredentials[1],
    });

    Map<String, String> headers = {
      "Content-type": "application/json",
      "Accept": "application/json",
    };

    http.Response items;
    try {
      items = await http
        .post(Uri.parse(GlobalVars().serverUrl + "/api/v1/get_cart_items"),
            body: body, headers: headers)
        .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      return {"success": false, "message": "Server timed out"};
    }

    if (items.statusCode == 200) {
      var body = json.decode(items.body);
      if (body["success"]) {
        return {"success": true, "items": List<String>.from(body["items"])};
      }
    }
    return {"success": false, "message": "User Not Found"};
  }

  Future<Map<String, dynamic>> addItemToCart(String item) async {
    if (!initialized) {
      await _doneFuture;
    }

    if (userCredentials.length != 2) {
      return {
        "success": false,
        "message": "Please Login or Sign Up Before Adding Items to Cart"
      };
    }

    var body = json.encode({
      "email": userCredentials[0],
      "password": userCredentials[1],
      "item": item,
    });

    Map<String, String> headers = {
      "Content-type": "application/json",
      "Accept": "application/json",
    };

    var response = await http
        .post(Uri.parse(GlobalVars().serverUrl + "/api/v1/add_item_to_cart"),
            body: body, headers: headers)
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      if (body["success"]) {
        return {"success": true};
      }
    }
    return {"success": false, "message": "User not found"};
  }
}
