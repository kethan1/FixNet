import os
from dotenv import load_dotenv
from flask import *
from flask_pymongo import PyMongo
import datetime

if "DYNO" not in os.environ:
    load_dotenv()

app = Flask(__name__)
app.config["MONGO_URI"] = f"mongodb+srv://{os.environ['user']}:{os.environ['password']}@full-stack-web-developm.m7o9n.mongodb.net/ecommerce_app?retryWrites=true&w=majority"
mongo = PyMongo(app)


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
    if mongo.db.movies.find_one({"email": email}) is None:
        mongo.db.movies.insert_one({
            "firstname": firstname,
            "lastname": lastname,
            "password": password,
            "email": email,
            "signuptime": current_time,
            "cart": []
        })
        return {"errorCode": 0, "success": True}
    return {"errorCode": 1, "success": False, "message": "Email taken"}


@app.route("/api/v1/login", methods=["POST"])
def login():
    password = request.json["password"]
    email = request.json["email"]
    if mongo.db.movies.find_one({"email": email, "password": password}) is not None:
        return {"errorCode": 0, "success": True}
    return {"errorCode": 2, "success": False, "message": "Email or password is wrong"}


@app.route("/api/v1/add_item_to_cart", methods=["POST"])
def add_item_to_cart():
    password = request.json["password"]
    email = request.json["email"]
    item = request.json["item"]
    if mongo.db.movies.find_one({"email": email, "password": password}) is not None:
        mongo.db.movies.update_one(
            {"email": email, "password": password},
            {"$push": {"cart": item}},
        )
        return {"errorCode": 0, "success": True}
    return {"errorCode": 3, "success": False, "message": "User not found"}


if __name__ == "__main__":
    app.run(debug=True)
