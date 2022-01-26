import os
import sys
import pymongo
import gridfs
from dotenv import load_dotenv

load_dotenv("server/.env")

filename = os.path.basename(sys.argv[1]).split(".")[0]
print(filename)

if len(sys.argv) > 2:
    collection_name = sys.argv[2]

db_client = pymongo.MongoClient(f"mongodb+srv://{os.environ['user']}:{os.environ['password']}@full-stack-web-developm.m7o9n.mongodb.net/ecommerce_app?retryWrites=true&w=majority")

db = db_client.ecommerce_app
fs = gridfs.GridFS(db, collection=collection_name)

result = fs.find_one({"name": filename})

# now use the _id to delete the file
files_id = result._id

fs.delete(files_id)
