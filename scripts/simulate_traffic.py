import requests
import threading
import time
import random
from datetime import datetime

# Configuration
NGINX_ENDPOINT = "http://ecommerce-prod-alb-729677946.eu-west-1.elb.amazonaws.com"  
USERS = 50
REQUESTS_PER_USER = 50
SLEEP_TIME = 0.2  # seconds between requests

ENDPOINTS = [
    "/products/",
    "/products/1",
    "/cart/?user_id={user_id}",
    "/orders/?user_id={user_id}"
]

def print_status():
    while True:
        print(f"{datetime.now().isoformat()} - Active threads: {threading.active_count()}")
        time.sleep(5)

def simulate_user(user_id):
    session = requests.Session()
    for i in range(REQUESTS_PER_USER):
        endpoint = random.choice(ENDPOINTS).format(user_id=user_id)
        url = f"{NGINX_ENDPOINT}{endpoint}"
        
        try:
            if "cart" in endpoint:
                if random.random() > 0.7:  # 30% chance to modify cart
                    product_id = random.randint(1, 15)
                    data = {
                        "user_id": user_id,
                        "product_id": product_id,
                        "quantity": random.randint(1, 3)
                    }
                    response = session.post(f"{NGINX_ENDPOINT}/cart/items/", json=data)
            elif "orders" in endpoint and random.random() > 0.9:  # 10% chance to create order
                response = session.post(f"{NGINX_ENDPOINT}/orders/", json={"user_id": user_id})
            else:
                response = session.get(url)
            
            print(f"User {user_id} - {response.status_code} {url}")
        except Exception as e:
            print(f"User {user_id} - Error: {str(e)}")
        
        time.sleep(SLEEP_TIME + random.random())  # Add some jitter

if __name__ == "__main__":
    print(f"Starting traffic simulation at {datetime.now().isoformat()}")
    print(f"Config: {USERS} users, {REQUESTS_PER_USER} requests each")
    
    # Start status thread
    threading.Thread(target=print_status, daemon=True).start()
    
    # Start user threads
    threads = []
    for user_id in range(1, USERS + 1):
        thread = threading.Thread(target=simulate_user, args=(user_id,))
        threads.append(thread)
        thread.start()
        time.sleep(0.1)  # Stagger thread starts
    
    for thread in threads:
        thread.join()
    
    print(f"Simulation completed at {datetime.now().isoformat()}")