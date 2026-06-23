import csv
import random
from datetime import date, timedelta
from faker import Faker

fake = Faker()
random.seed(42)
Faker.seed(42)

# output paths
PRODUCTS_FILE = "data/products.csv"
EVENTS_FILE = "data/events.csv"
CUSTOMERS_FILE = "data/customers.csv"
ORDERS_FILE = "data/orders.csv"
ORDER_ITEMS_FILE = "data/order_items.csv"
INVENTORY_FILE = "data/inventory.csv"

# san diego zip codes
SD_ZIPS = [
    "92101", "92103", "92104", "92105", "92108",
    "92109", "92110", "92111", "92115", "92116",
    "92117", "92120", "92123", "92124", "92130",
    "92131", "92037", "92014", "92024", "92054"
]

# vietnamese first names mixed with common american names
FIRST_NAMES_POOL = [
    "Linh", "Minh", "Trang", "Hoa", "Bao", "Lan", "Tuyen", "Phuong",
    "Duc", "Ngan", "Vy", "Khoa", "Thy", "Nam", "Mai", "Thanh",
    "Jessica", "Sarah", "Emily", "Rachel", "Ashley", "Megan", "Nicole",
    "Lauren", "Brittany", "Amanda", "Stephanie", "Jennifer", "Melissa",
    "Daniel", "Chris", "Kevin", "Ryan", "James", "Michael", "David",
    "Jason", "Andrew", "Brian", "Carlos", "Maria", "Sofia", "Ana",
    "Isabel", "Diego", "Luis", "Elena", "Rosa", "Marcus", "Jordan"
]

# purchase type config
PURCHASE_TYPES = {
    "individual": {"unit_price": 5.00, "size": 1},
    "3_pack":     {"unit_price": 4.33, "size": 3},
    "6_pack":     {"unit_price": 4.00, "size": 6},
}

PURCHASE_TYPE_WEIGHTS = [0.45, 0.35, 0.20]


def write_csv(filepath, fieldnames, rows):
    with open(filepath, "w", newline="\n", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"  wrote {len(rows)} rows -> {filepath}")


# products

def generate_products():
    products = [
        {
            "product_id": 1,
            "product_name": "Matcha White Chocolate",
            "flavor_profile": "tea_based",
            "base_price": 5.00,
            "is_seasonal": False,
            "season": "",
            "is_crowd_favorite": False,
            "is_active": True,
        },
        {
            "product_id": 2,
            "product_name": "Hojicha White Chocolate",
            "flavor_profile": "tea_based",
            "base_price": 5.00,
            "is_seasonal": False,
            "season": "",
            "is_crowd_favorite": False,
            "is_active": True,
        },
        {
            "product_id": 3,
            "product_name": "Strawberry Milk Tea",
            "flavor_profile": "tea_based",
            "base_price": 5.00,
            "is_seasonal": False,
            "season": "",
            "is_crowd_favorite": True,
            "is_active": True,
        },
        {
            "product_id": 4,
            "product_name": "Thai Tea",
            "flavor_profile": "tea_based",
            "base_price": 5.00,
            "is_seasonal": False,
            "season": "",
            "is_crowd_favorite": False,
            "is_active": True,
        },
        {
            "product_id": 5,
            "product_name": "Vietnamese Coffee",
            "flavor_profile": "nutty_roasted",
            "base_price": 5.00,
            "is_seasonal": False,
            "season": "",
            "is_crowd_favorite": False,
            "is_active": True,
        },
        {
            "product_id": 6,
            "product_name": "Black Sesame Dark Chocolate",
            "flavor_profile": "nutty_roasted",
            "base_price": 5.00,
            "is_seasonal": False,
            "season": "",
            "is_crowd_favorite": False,
            "is_active": True,
        },
        {
            "product_id": 7,
            "product_name": "Honey Sesame",
            "flavor_profile": "nutty_roasted",
            "base_price": 5.00,
            "is_seasonal": False,
            "season": "",
            "is_crowd_favorite": True,
            "is_active": True,
        },
        {
            "product_id": 8,
            "product_name": "Pandan Coconut",
            "flavor_profile": "sweet_nostalgic",
            "base_price": 5.00,
            "is_seasonal": False,
            "season": "",
            "is_crowd_favorite": True,
            "is_active": True,
        },
        {
            "product_id": 9,
            "product_name": "Classic Chocolate Chip",
            "flavor_profile": "sweet_nostalgic",
            "base_price": 5.00,
            "is_seasonal": False,
            "season": "",
            "is_crowd_favorite": False,
            "is_active": True,
        },
        {
            "product_id": 10,
            "product_name": "Bolo Bao",
            "flavor_profile": "sweet_nostalgic",
            "base_price": 5.00,
            "is_seasonal": True,
            "season": "spring_summer",
            "is_crowd_favorite": False,
            "is_active": True,
        },
        {
            "product_id": 11,
            "product_name": "Sweet Corn",
            "flavor_profile": "sweet_nostalgic",
            "base_price": 5.00,
            "is_seasonal": True,
            "season": "fall_winter",
            "is_crowd_favorite": False,
            "is_active": True,
        },
        {
            "product_id": 12,
            "product_name": "Vietnamese Fried Banana",
            "flavor_profile": "sweet_nostalgic",
            "base_price": 5.00,
            "is_seasonal": False,
            "season": "",
            "is_crowd_favorite": False,
            "is_active": True,
        },
    ]

    for p in products:
        p["is_seasonal"]       = 1 if p["is_seasonal"] else 0
        p["is_crowd_favorite"] = 1 if p["is_crowd_favorite"] else 0
        p["is_active"]         = 1 if p["is_active"] else 0
        if p["season"] == "":
            p["season"] = None

    write_csv(
        PRODUCTS_FILE,
        ["product_id", "product_name", "flavor_profile", "base_price",
         "is_seasonal", "season", "is_crowd_favorite", "is_active"],
        products
    )
    return products


# events

def generate_events():
    events = []
    event_id = 1

    # dummy online pickup event — always event_id 1
    events.append({
        "event_id": event_id,
        "event_name": "Online Pickup",
        "event_type": "online_pickup",
        "event_date": "",
        "neighborhood": "Home Kitchen",
        "duration_hours": "",
        "booth_fee": 0.00,
        "estimated_attendance": "",
        "weather_condition": "sunny",
    })
    event_id += 1

    # recurring cafe popups every other weekend, Jan 2024 - Dec 2024
    cafe_locations = [
        ("North Park Cafe Popup", "cafe_popup", "North Park"),
        ("Convoy Cafe Popup",     "cafe_popup", "Convoy"),
    ]

    start = date(2024, 1, 6)
    end   = date(2024, 12, 31)
    current = start
    toggle = 0

    while current <= end:
        loc = cafe_locations[toggle % 2]
        weather = random.choices(
            ["sunny", "cloudy", "rainy", "hot"],
            weights=[0.55, 0.25, 0.10, 0.10]
        )[0]
        events.append({
            "event_id": event_id,
            "event_name": loc[0],
            "event_type": loc[1],
            "event_date": current.isoformat(),
            "neighborhood": loc[2],
            "duration_hours": random.choice([3.0, 4.0, 4.5]),
            "booth_fee": 0.00,
            "estimated_attendance": random.randint(60, 120),
            "weather_condition": weather,
        })
        event_id += 1
        toggle += 1
        current += timedelta(weeks=2)

    # festivals and markets
    special_events = [
        ("Lunar New Year Festival", "festival",  "Convoy",        date(2024, 2, 10), 6.0,  150.00, 800),
        ("North Park Farmers Market","market",   "North Park",    date(2024, 3, 16), 4.0,   60.00, 300),
        ("San Diego Night Market",   "festival", "Little Italy",  date(2024, 4, 20), 5.0,  200.00, 1200),
        ("Asian Food Fest",          "festival", "Kearny Mesa",   date(2024, 5, 18), 6.0,  175.00, 900),
        ("Mission Hills Market",     "market",   "Mission Hills", date(2024, 6, 8),  4.0,   60.00, 250),
        ("Summer Night Bazaar",      "festival", "Barrio Logan",  date(2024, 7, 13), 5.0,  125.00, 700),
        ("Little Italy Mercato",     "market",   "Little Italy",  date(2024, 8, 17), 4.0,   75.00, 400),
        ("Mid-Autumn Festival",      "festival", "Convoy",        date(2024, 9, 14), 5.0,  150.00, 850),
        ("Fall Harvest Market",      "market",   "North Park",    date(2024, 10, 5), 4.0,   60.00, 280),
        ("Holiday Night Market",     "festival", "Little Italy",  date(2024, 11, 23),6.0,  200.00, 1000),
        ("Winter Pop-Up",            "festival", "Convoy",        date(2024, 12, 14),5.0,  125.00, 600),
    ]

    for name, etype, hood, edate, dur, fee, att in special_events:
        weather = random.choices(
            ["sunny", "cloudy", "rainy", "hot"],
            weights=[0.55, 0.25, 0.10, 0.10]
        )[0]
        events.append({
            "event_id": event_id,
            "event_name": name,
            "event_type": etype,
            "event_date": edate.isoformat(),
            "neighborhood": hood,
            "duration_hours": dur,
            "booth_fee": fee,
            "estimated_attendance": att,
            "weather_condition": weather,
        })
        event_id += 1

    write_csv(
        EVENTS_FILE,
        ["event_id", "event_name", "event_type", "event_date", "neighborhood",
         "duration_hours", "booth_fee", "estimated_attendance", "weather_condition"],
        events
    )
    return events


# customers

def generate_customers(events):
    real_events = [e for e in events if e["event_type"] != "online_pickup"]
    customers = []
    used_emails = set()

    for i in range(1, 1001):
        first_name = random.choice(FIRST_NAMES_POOL)
        last_name  = fake.last_name()
        email_base = f"{first_name.lower()}.{last_name.lower()}"
        email = f"{email_base}@{random.choice(['gmail.com','yahoo.com','outlook.com','icloud.com'])}"

        # deduplicate emails
        suffix = 1
        while email in used_emails:
            email = f"{email_base}{suffix}@{random.choice(['gmail.com','yahoo.com','outlook.com','icloud.com'])}"
            suffix += 1
        used_emails.add(email)

        acq_event = random.choice(real_events)

        customers.append({
            "customer_id":          i,
            "first_name":           first_name,
            "email":                email,
            "acquisition_event_id": acq_event["event_id"],
            "acquisition_date":     acq_event["event_date"],
            "zip_code":             random.choice(SD_ZIPS),
        })

    write_csv(
        CUSTOMERS_FILE,
        ["customer_id", "first_name", "email",
         "acquisition_event_id", "acquisition_date", "zip_code"],
        customers
    )
    return customers


# orders and order_items

def get_available_products(event_date_str, products):
    if not event_date_str:
        # online — no seasonal restriction
        return products

    event_date = date.fromisoformat(event_date_str)
    month = event_date.month
    in_spring_summer = 3 <= month <= 8
    in_fall_winter   = month >= 9 or month <= 2

    available = []
    for p in products:
        if not p["is_seasonal"]:
            available.append(p)
        elif p["season"] == "spring_summer" and in_spring_summer:
            available.append(p)
        elif p["season"] == "fall_winter" and in_fall_winter:
            available.append(p)
    return available


def pick_products_for_order(available_products, purchase_type):
    size = PURCHASE_TYPES[purchase_type]["size"]
    favorites     = [p for p in available_products if p["is_crowd_favorite"]]
    non_favorites = [p for p in available_products if not p["is_crowd_favorite"]]

    chosen = []
    for _ in range(size):
        if favorites and random.random() < 0.45:
            chosen.append(random.choice(favorites))
        else:
            chosen.append(random.choice(non_favorites if non_favorites else available_products))
    return chosen


def generate_orders_and_items(events, customers, products):
    event_map    = {e["event_id"]: e for e in events}
    customer_map = {c["customer_id"]: c for c in customers}

    # orders per event type
    orders_per_event = {
        "cafe_popup":      (25, 45),
        "festival":        (80, 140),
        "market":          (35, 60),
        "online_pickup":   (8, 18),
    }

    orders      = []
    order_items = []
    order_id      = 1
    order_item_id = 1

    # track quantity sold per (event_id, product_id) for inventory
    inventory_tracker = {}

    online_event = next(e for e in events if e["event_type"] == "online_pickup")

    for event in events:
        etype    = event["event_type"]
        lo, hi   = orders_per_event[etype]
        n_orders = random.randint(lo, hi)

        available_products = get_available_products(event["event_date"], products)
        is_online          = etype == "online_pickup"

        # spread online orders across the full year
        online_dates = []
        if is_online:
            year_start = date(2024, 1, 1)
            online_dates = [
                (year_start + timedelta(days=random.randint(0, 364))).isoformat()
                for _ in range(n_orders)
            ]

        eligible_customers = list(customer_map.values())

        for i in range(n_orders):
            customer = random.choice(eligible_customers)

            if is_online:
                order_date   = online_dates[i]
                order_channel = "online"
                event_id_for_order = online_event["event_id"]
            else:
                order_date   = event["event_date"]
                order_channel = "in_person"
                event_id_for_order = event["event_id"]

            purchase_type = random.choices(
                list(PURCHASE_TYPES.keys()),
                weights=PURCHASE_TYPE_WEIGHTS
            )[0]

            chosen_products = pick_products_for_order(available_products, purchase_type)
            unit_price      = PURCHASE_TYPES[purchase_type]["unit_price"]

            orders.append({
                "order_id":      order_id,
                "order_date":    order_date,
                "customer_id":   customer["customer_id"],
                "event_id":      event_id_for_order,
                "order_channel": order_channel,
            })

            for product in chosen_products:
                line_total = round(1 * unit_price, 2)
                order_items.append({
                    "order_item_id": order_item_id,
                    "order_id":      order_id,
                    "product_id":    product["product_id"],
                    "purchase_type": purchase_type,
                    "quantity":      1,
                    "unit_price":    unit_price,
                    "line_total":    line_total,
                })
                order_item_id += 1

                # track for inventory — only in-person events
                if not is_online:
                    key = (event_id_for_order, product["product_id"])
                    inventory_tracker[key] = inventory_tracker.get(key, 0) + 1

            order_id += 1

    write_csv(
        ORDERS_FILE,
        ["order_id", "order_date", "customer_id", "event_id", "order_channel"],
        orders
    )
    write_csv(
        ORDER_ITEMS_FILE,
        ["order_item_id", "order_id", "product_id", "purchase_type",
         "quantity", "unit_price", "line_total"],
        order_items
    )
    return inventory_tracker


# inventory

def generate_inventory(events, products, inventory_tracker):
    inventory = []
    inventory_id = 1

    real_events = [e for e in events if e["event_type"] != "online_pickup"]

    for event in real_events:
        available_products = get_available_products(event["event_date"], products)
        etype = event["event_type"]

        # base production quantities by event type
        base_qty = {
            "cafe_popup": (20, 40),
            "festival":   (60, 120),
            "market":     (30, 60),
        }
        lo, hi = base_qty.get(etype, (20, 40))

        for product in available_products:
            key          = (event["event_id"], product["product_id"])
            qty_sold     = inventory_tracker.get(key, 0)

            # produced must be >= sold; add a realistic buffer
            buffer       = random.randint(5, 20)
            qty_produced = max(qty_sold + buffer, random.randint(lo, hi))

            inventory.append({
                "inventory_id":      inventory_id,
                "event_id":          event["event_id"],
                "product_id":        product["product_id"],
                "quantity_produced": qty_produced,
                "quantity_sold":     qty_sold,
            })
            inventory_id += 1

    write_csv(
        INVENTORY_FILE,
        ["inventory_id", "event_id", "product_id",
         "quantity_produced", "quantity_sold"],
        inventory
    )


# main

def main():
    print("generating products...")
    products = generate_products()

    print("generating events...")
    events = generate_events()

    print("generating customers...")
    customers = generate_customers(events)

    print("generating orders and order_items...")
    inventory_tracker = generate_orders_and_items(events, customers, products)

    print("generating inventory...")
    generate_inventory(events, products, inventory_tracker)

    print("\ndone. all 6 CSVs written to data/")


def fix_line_endings():
    files = [
        "data/products.csv",
        "data/events.csv",
        "data/customers.csv",
        "data/orders.csv",
        "data/order_items.csv",
        "data/inventory.csv",
    ]
    for f in files:
        content = open(f, "rb").read()
        open(f, "wb").write(content.replace(b"\r\n", b"\n"))

if __name__ == "__main__":
    main()
    fix_line_endings()
    print("line endings normalized")