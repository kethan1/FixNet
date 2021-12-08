import os
from dotenv import load_dotenv
from flask import *
from flask_pymongo import PyMongo

if "DYNO" not in os.environ:
    load_dotenv()

app = Flask(__name__)
app.config["MONGO_URI"] = f"mongodb+srv://{os.environ['user']}:{os.environ['password']}@full-stack-web-developm.m7o9n.mongodb.net/ecommerce_app?retryWrites=true&w=majority"
mongo = PyMongo(app)


@app.route("/api/v1/get_movies")
def get_movies():
    print(list(mongo.db.movies.find()))
    return jsonify([
        {key: value for key, value in movie.items() if key != "_id"}
        for movie in mongo.db.movies.find()
    ])

@app.route("/api/v1/add_movie")
def upload_movie():
    title = request.json["title"]

if __name__ == "__main__":
    app.run(debug=True)
