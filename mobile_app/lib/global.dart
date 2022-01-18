import "dart:async";

import "package:flutter/foundation.dart" show kIsWeb;
import "package:shared_preferences/shared_preferences.dart";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "dart:convert";

class GlobalVars {
  bool debug = true;
  late String serverUrl = debug
      ? (kIsWeb ? "http://localhost:5000" : "http://10.0.2.2:5000")
      : "https://fixnet.herokuapp.com";

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
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.red,
            ),
            child: Text(""),
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
          if (UserInfo().signedIn)
            ListTile(
              title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.video_library),
                  Text(" Library", style: bigFont),
                ],
              ),
              onTap: () => Navigator.pushNamed(context, "/library"),
            ),
          if (!UserInfo().initialized || !UserInfo().signedIn)
            ListTile(
              title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.login_outlined, size: 25.0),
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
                  const Icon(Icons.login_outlined, size: 25.0),
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
                  const Icon(Icons.logout_outlined, size: 25.0),
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

  Widget getImage(String image, {bool fullSize = false}) {
    return Image.network(
      "${GlobalVars().serverUrl}/api/v1/get_movie_poster/$image-${fullSize ? 'horizontal' : 'vertical'}",
    );
  }

  ImageProvider getImageProvider(String image, {bool fullSize = false}) {
    return NetworkImage(
      "${GlobalVars().serverUrl}/api/v1/get_movie_poster/$image-${fullSize ? 'horizontal' : 'vertical'}",
    );
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
        if (userCredentials.length >= 2) {
          await UserInfo()
              .login(userCredentials[0], userCredentials[1], initialize: false);
        }
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

  Future<Map<String, dynamic>> login(String email, String password,
      {bool initialize = false}) async {
    if (!initialized && !initialize) {
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
      return {"success": false, "message": body["message"]};
    }
    return {"success": false, "message": "Could not complete request"};
  }

  Future<Map<String, dynamic>> removeItemFromCart(String item) async {
    if (!initialized) {
      await _doneFuture;
    }

    if (userCredentials.length != 2) {
      return {
        "success": false,
        "message": "Please Login or Sign Up Before Removing Items from Cart"
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
        .post(Uri.parse(GlobalVars().serverUrl + "/api/v1/remove_cart_item"),
            body: body, headers: headers)
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      if (body["success"]) {
        return {"success": true};
      } else if (body["message"] == "Item not found") {
        return {"success": false, "message": "Item not found"};
      }
    }
    return {"success": false, "message": "User not found"};
  }

  Future<Map<String, dynamic>> getLibraryItems() async {
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
          .post(Uri.parse(GlobalVars().serverUrl + "/api/v1/get_library_items"),
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

  Future<Map<String, dynamic>> addItemToLibrary(String item) async {
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
        .post(Uri.parse(GlobalVars().serverUrl + "/api/v1/add_item_to_library"),
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
