import pymongo
import gridfs
import os
import sys
from dotenv import load_dotenv

load_dotenv("server/.env")

filesize = os.path.getsize(sys.argv[1])
filename = os.path.basename(sys.argv[1]).split(".")[0]
print(filesize)
print(filename)

if len(sys.argv) > 1:
    collection_name = sys.argv[1]

db_client = pymongo.MongoClient(f"mongodb+srv://{os.environ['user']}:{os.environ['password']}@full-stack-web-developm.m7o9n.mongodb.net/ecommerce_app?retryWrites=true&w=majority")

db = db_client.ecommerce_app

fs = gridfs.GridFS(db, collection=collection_name)

print([movie["name"] for movie in db[f"{collection_name}.files"].find({})])
