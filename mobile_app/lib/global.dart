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

class CartObjs {
  List<String> inCart = [];
  dynamic prefs;
  bool initialized = false;
  Future? _doneFuture;

  init() async {
    if (!initialized) {
      prefs = await SharedPreferences.getInstance();
      if (prefs.getStringList("inCart") == null) {
        prefs.setStringList("inCart", <String>[]);
      } else {
        inCart = List<String>.from(prefs.getStringList("inCart")!);
      }
      initialized = true;
    }
  }

  static final CartObjs _singleton = CartObjs._internal();

  factory CartObjs() {
    _singleton._doneFuture = _singleton.init();
    return _singleton;
  }

  CartObjs._internal();

  Future<List<String>> getItemsFromCart() async {
    if (!initialized) {
      await _doneFuture;
    }
    return prefs.getStringList("inCart");
  }

  Future<void> addItemtoCart(String title) async {
    if (!initialized) {
      await _doneFuture;
    }
    List itemsInCart = await getItemsFromCart();
    if (!itemsInCart.contains(title)) {
      inCart.add(title);
    }
    prefs.setStringList("inCart", inCart);
  }

  void removeItemFromCart(String title) async {
    if (!initialized) {
      await _doneFuture;
    }
    inCart.remove(title);
    prefs.setStringList("inCart", inCart);
  }
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

  Future<Map<String, bool>> login(String email, String password) async {
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
    var response = await http
        .post(Uri.parse(GlobalVars().serverUrl + "/api/v1/login"),
            body: body, headers: headers)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      if (body["success"]) {
        userCredentials = [email, password];
        prefs.setStringList("usercredentials", userCredentials);
        return {"success": true};
      }
    }
    return {"success": false};
  }

  Future<Map<String, bool>> signup(
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
    var response = await http
        .post(Uri.parse(GlobalVars().serverUrl + "/api/v1/signup"),
            body: body, headers: headers)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      if (body["success"]) {
        userCredentials = [email, password];
        prefs.setStringList("usercredentials", userCredentials);
        return {"success": true};
      }
    }
    return {"success": false};
  }

  void logout() async {
    if (!initialized) {
      await _doneFuture;
    }
    userCredentials = [];
    prefs.setStringList("usercredentials", userCredentials);
  }
}
