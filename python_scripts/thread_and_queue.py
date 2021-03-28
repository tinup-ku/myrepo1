#!/usr/bin/python
import subprocess,os,threading,time
import Queue

lock=threading.Lock()
_start=time.time()

def check_ping(n):
    with open(os.devnull, "wb") as send_to_null:
                ip="192.168.4.{0}".format(n)
                result=subprocess.Popen(["ping", "-w", "1", ip],stdout=send_to_null, stderr=send_to_null).wait()
                with lock:                    
                    if not result:
                        print (ip, "Pass")                    
                    else:
                        pass
                        #print (ip, "Failed")                    

def threader():
    while True:
        q_each=q.get()
        check_ping(q_each)
        q.task_done()

#
q = Queue.Queue()

# Start 50 threads to read the queue
for _ in range(80):
    t=threading.Thread(target=threader)
    t.daemon=True
    t.start()

# place the numbers in queue to process with threads.
for mynum in range(1,255):
    q.put(mynum)
q.join()

print("Process completed in: ",time.time()-_start)

