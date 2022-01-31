import os
import re
import datetime

from dotenv import load_dotenv
from flask import Flask, jsonify, request, Response, make_response
from flask_pymongo import PyMongo
from flask_cors import CORS
from gridfs import GridFS

if "DYNO" not in os.environ:
    load_dotenv()

app = Flask(__name__)
app.config["MONGO_URI"] = os.environ["database_url"].replace("$user", os.environ["user"]).replace("$password", os.environ["password"])
mongo = PyMongo(app)
cors = CORS(app, resources={r"/api/*": {"origins": "*"}})


@app.route("/api/v1/get-movies")
def get_movies():
    return jsonify([
        {key: value for key, value in movie.items() if key != "_id"}
        for movie in mongo.db.movies.find()
    ])


@app.route("/api/v1/add-review", methods=["POST"])
def upload_movie():
    movie_title = request.json["movie_title"]
    movie_review = request.json["description"]
    stars = request.json["stars"]

    mongo.db.movies.update_one(
        {"title": movie_title},
        {"$push": {"ratings": {"stars": stars, "description": movie_review}}},
    )
    return "True"


@app.route("/api/v1/signup", methods=["POST"])
def signup():
    firstname = request.json["firstname"]
    lastname = request.json["lastname"]
    password = request.json["password"]
    email = request.json["email"]
    current_time = datetime.datetime.now()
    if mongo.db.users.find_one({"email": email}) is None:
        mongo.db.users.insert_one({
            "firstname": firstname,
            "lastname": lastname,
            "password": password,
            "email": email,
            "signuptime": current_time,
            "cart": [],
            "library": []
        })
        return {"errorCode": 0, "success": True}
    return {"errorCode": 1, "success": False, "message": "Email taken"}


@app.route("/api/v1/login", methods=["POST"])
def login():
    password = request.json["password"]
    email = request.json["email"]
    if mongo.db.users.find_one({"email": email, "password": password}) is not None:
        return {"errorCode": 0, "success": True}
    return {"errorCode": 2, "success": False, "message": "Email or password is wrong"}


@app.route("/api/v1/get-name", methods=["POST"])
def get_name():
    email = request.json["email"]
    found = mongo.db.users.find_one({"email": email})
    if found is not None:
        return {"success": True, "firstname": found["firstname"], "lastname": found["lastname"]}
    return {"errorCode": 9, "success": False, "message": "User with that email not found"}


@app.route("/api/v1/add-item-to-cart", methods=["POST"])
def add_item_to_cart():
    password = request.json["password"]
    email = request.json["email"]
    item = request.json["item"]
    user = mongo.db.users.find_one({"email": email, "password": password})
    if user is not None:
        if item not in user["cart"]:
            if item not in user["library"]:
                mongo.db.users.update_one(
                    {"email": email, "password": password},
                    {"$push": {"cart": item}},
                )
                return {"errorCode": 0, "success": True}
            return {"errorCode": 7, "success": False, "message": "Item already in library"}
        return {"errorCode": 5, "success": False, "message": "Item already in cart"}
    return {"errorCode": 3, "success": False, "message": "User not found"}


@app.route("/api/v1/get-cart-items", methods=["POST"])
def get_cart_items():
    password = request.json["password"]
    email = request.json["email"]
    user = mongo.db.users.find_one({"email": email, "password": password})
    if user is not None:
        items = user["cart"]
        return {"errorCode": 0, "success": True, "items": items}
    return {"errorCode": 3, "success": False, "message": "User not found"}


@app.route("/api/v1/remove-cart-item", methods=["POST"])
def remove_cart_item():
    password = request.json["password"]
    email = request.json["email"]
    item = request.json["item"]
    user = mongo.db.users.find_one({"email": email, "password": password})
    if user is not None:
        items = user["cart"]
        if item in items:
            items.remove(item)
            mongo.db.users.update_one(
                {"email": email, "password": password},
                {"$set": {"cart": items}}
            )
            return {"errorCode": 0, "success": True}
        return {"errorCode": 4, "success": True, "message": "Item not found"}
    return {"errorCode": 3, "success": False, "message": "User not found"}


@app.route("/api/v1/add-item-to-library", methods=["POST"])
def add_item_to_library():
    password = request.json["password"]
    email = request.json["email"]
    item = request.json["item"]
    user = mongo.db.users.find_one({"email": email, "password": password})
    if user is not None:
        if item not in user["library"]:
            mongo.db.users.update_one(
                {"email": email, "password": password},
                {"$push": {"library": item}},
            )
            return {"errorCode": 0, "success": True}
        return {"errorCode": 6, "success": False, "message": "Item already in library"}
    return {"errorCode": 3, "success": False, "message": "User not found"}


@app.route("/api/v1/get-library-items", methods=["POST"])
def get_library_items():
    password = request.json["password"]
    email = request.json["email"]
    if mongo.db.users.find_one({"email": email, "password": password}) is not None:
        items = mongo.db.users.find_one(
            {"email": email, "password": password})["library"]
        return {"errorCode": 0, "success": True, "items": items}
    return {"errorCode": 3, "success": False, "message": "User not found"}


@app.route("/api/v1/get-featured-movies")
def get_featured_movies():
    return jsonify(mongo.db.ui_metadata.find({})[0]["featured_movies"])


@app.route("/api/v1/stream-movie/<file_name>", methods=["GET", "POST"])
def stream_movie(file_name):
    db = mongo.db
    fs = GridFS(db, collection="movies")
    regex = re.compile(file_name, re.IGNORECASE)
    f = fs.find_one({"name": regex})

    if f is None:
        raise ValueError("File not found!")

    response = make_response(f.read())
    response.mimetype = "video/mp4"
    return response


@app.route("/api/v1/stream-trailer/<file_name>", methods=["GET", "POST"])
def stream_trailer(file_name):
    db = mongo.db
    fs = GridFS(db, collection="movie_trailers")
    regex = re.compile(file_name + "-trailer", re.IGNORECASE)
    f = fs.find_one({"name": regex})

    if f is None:
        raise ValueError("File not found!")

    response = make_response(f.read())
    response.mimetype = "video/mp4"
    return response


@app.route("/api/v1/get-movie-poster/<file_name>", methods=["GET", "POST"])
def get_movie_poster(file_name):
    db = mongo.db
    fs = GridFS(db, collection="movie_posters")
    f = fs.find_one({"name": file_name})

    if f is None:
        raise ValueError("File not found!")

    return Response(f, mimetype="image/jpg")


if __name__ == "__main__":
    app.run(debug=True)
