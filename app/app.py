import socket
import time
from flask import Flask

app = Flask(__name__)

@app.get("/")
def serverName():
    return socket.gethostname()

@app.get("/load")
def increaseLoad():
    end = time.time()+3
    while(time.time() < end):
        2132831038 * 12371231
    return "done"

          
app.run(host="0.0.0.0", port=5000)