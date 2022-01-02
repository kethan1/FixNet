import os
import datetime

from dotenv import load_dotenv
from flask import *
from flask_pymongo import PyMongo
from flask_cors import CORS
from gridfs import GridFS

if "DYNO" not in os.environ:
    load_dotenv()

app = Flask(__name__)
app.config["MONGO_URI"] = f"mongodb+srv://{os.environ['user']}:{os.environ['password']}@full-stack-web-developm.m7o9n.mongodb.net/ecommerce_app?retryWrites=true&w=majority"
mongo = PyMongo(app)
cors = CORS(app, resources={r"/api/*": {"origins": "*"}})


@app.route("/api/v1/get_movies")
def get_movies():
    return jsonify([
        {key: value for key, value in movie.items() if key != "_id"}
        for movie in mongo.db.movies.find()
    ])


@app.route("/api/v1/add_review", methods=["POST"])
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


@app.route("/api/v1/add_item_to_cart", methods=["POST"])
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


@app.route("/api/v1/get_cart_items", methods=["POST"])
def get_cart_items():
    password = request.json["password"]
    email = request.json["email"]
    user = mongo.db.users.find_one({"email": email, "password": password})
    if user is not None:
        items = user["cart"]
        return {"errorCode": 0, "success": True, "items": items}
    return {"errorCode": 3, "success": False, "message": "User not found"}


@app.route("/api/v1/remove_cart_item", methods=["POST"])
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


@app.route("/api/v1/add_item_to_library", methods=["POST"])
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


@app.route("/api/v1/get_library_items", methods=["POST"])
def get_library_items():
    password = request.json["password"]
    email = request.json["email"]
    if mongo.db.users.find_one({"email": email, "password": password}) is not None:
        items = mongo.db.users.find_one(
            {"email": email, "password": password})["library"]
        return {"errorCode": 0, "success": True, "items": items}
    return {"errorCode": 3, "success": False, "message": "User not found"}


@app.route("/api/v1/client/serve/<file_name>/", methods=["GET", "POST"])
def serve_file(file_name):
    db = mongo.db
    fs = GridFS(db)
    f = fs.find_one({"name": file_name})

    if f is None:
        raise ValueError("File not found!")

    response = make_response(f.read())
    response.mimetype = "video/mp4"
    return response


if __name__ == "__main__":
    app.run(debug=True)
