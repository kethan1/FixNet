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

db_client = pymongo.MongoClient(f"mongodb+srv://{os.environ['user']}:{os.environ['password']}@full-stack-web-developm.m7o9n.mongodb.net/ecommerce_app?retryWrites=true&w=majority")

db = db_client.ecommerce_app

fs = gridfs.GridFS(db)
fileID = fs.put(open(sys.argv[1], 'rb'), name=os.path.basename(filename))
out = fs.get(fileID)
print(out.length)

if filesize != out.length:
    print("Uploading of file failed")
