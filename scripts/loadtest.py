import requests
import time
import threading


def worker():
    end = time.time() + 600
    while(time.time() < end):
        store = requests.get("http://autoscaling-albdufjrod-1564415628.ap-northeast-2.elb.amazonaws.com/load")
        print(store.text)

for i in range(10):
    t = threading.Thread(target=worker)
    t.start()