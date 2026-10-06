import os
import random
import uuid
from datetime import datetime, timedelta

import numpy as np
import pandas as pd


# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------
SEED = 42

np.random.seed(SEED)
uuid_rng = random.Random(SEED)

STATUS_VALUES = ["Completed", "Cancelled", "Pending"]
STATUS_PROBABILITIES = [0.98, 0.015, 0.005]

# Pending lifecycle during February:
# 85% -> Completed
# 10% -> Cancelled
# 5% -> remain Pending
PENDING_TO_COMPLETED = 0.85
PENDING_TO_CANCELLED = 0.10


# ---------------------------------------------------------
# OUTPUT STRUCTURE
# ---------------------------------------------------------
script_dir = os.path.dirname(os.path.abspath(__file__))

# Expected project layout:
# 2-Retail_Datasets/
# 4-Documentation/Scripts/1-Data_Generation.py
project_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
datasets_root = os.path.join(project_root, "2-Retail_Datasets")

if os.path.isdir(datasets_root):
    output_dir = os.path.join(datasets_root, "Retail_Project_Data_New")
else:
    # Fallback if the script is run outside the project structure.
    output_dir = os.path.join(script_dir, "Retail_Project_Data_New")

initial_dir = os.path.join(output_dir, "1_Initial_Load")
incremental_dir = os.path.join(output_dir, "2_Incremental_Load")

os.makedirs(initial_dir, exist_ok=True)
os.makedirs(incremental_dir, exist_ok=True)


# ---------------------------------------------------------
# HELPERS
# ---------------------------------------------------------
def deterministic_uuid():
    """Return a repeatable UUID-shaped identifier."""
    return str(uuid.UUID(int=uuid_rng.getrandbits(128), version=4))


def choose_order_status():
    """Initial status distribution for every newly created invoice."""
    return np.random.choice(
        STATUS_VALUES,
        p=STATUS_PROBABILITIES
    )


# ---------------------------------------------------------
# 1. MASTER DATA
# ---------------------------------------------------------
print("Generating master data...")

stores = pd.DataFrame({
    "StoreID": range(1, 201),
    "StoreName": [f"Store_{i}" for i in range(1, 201)],
    "Region": np.random.choice(["North", "South", "East", "West"], 200),
    "City": np.random.choice(
        ["Cairo", "Alexandria", "Giza", "Mansoura", "Aswan"], 200
    )
})

products = pd.DataFrame({
    "ProductID": range(1, 101),
    "ProductName": [f"Product_{i}" for i in range(1, 101)],
    "Category": np.random.choice(
        ["Electronics", "Clothing", "Grocery", "Home Appliances"], 100
    ),
    "UnitPrice": np.round(np.random.uniform(10, 1000, 100), 2)
})

stores.to_csv(
    os.path.join(initial_dir, "Stores_Catalog.csv"),
    index=False
)

products.to_csv(
    os.path.join(initial_dir, "Products_Master.csv"),
    index=False
)

# Every invoice line uses the price of its selected ProductID.
product_price_map = products.set_index("ProductID")["UnitPrice"].to_dict()


# ---------------------------------------------------------
# 2. TRANSACTION GENERATOR
# ---------------------------------------------------------
def generate_transactions(start_date, end_date):
    """
    Generate transactions from start_date inclusive to end_date exclusive.

    Business rules:
    - Invoice Header is current-state transactional data.
    - Invoice Lines are immutable for this project scope.
    - New invoice status:
        98% Completed
        1.5% Cancelled
        0.5% Pending
    - At creation:
        LastModifiedAt = InvoiceDate
    """
    headers = []
    lines = []

    current_date = start_date

    while current_date < end_date:

        for store_id in range(1, 201):

            # Roughly 30-69 invoices per store per day.
            num_invoices = np.random.randint(30, 70)

            for _ in range(num_invoices):
                invoice_id = deterministic_uuid()

                # Random transaction time during store operating hours.
                inv_time = current_date + timedelta(
                    hours=int(np.random.randint(8, 22)),
                    minutes=int(np.random.randint(0, 59))
                )

                invoice_timestamp = inv_time.strftime("%Y-%m-%d %H:%M:%S")
                order_status = choose_order_status()

                headers.append({
                    "InvoiceID": invoice_id,
                    "StoreID": store_id,
                    "InvoiceDate": invoice_timestamp,
                    "PaymentMethod": np.random.choice(
                        ["Cash", "Credit Card", "Wallet"]
                    ),
                    "OrderStatus": order_status,
                    "LastModifiedAt": invoice_timestamp
                })

                # Each invoice contains 1-3 product lines.
                num_lines = np.random.randint(1, 4)

                for _ in range(num_lines):

                    # Intentional data-quality issue:
                    # ~5% of quantities are NULL for Silver-layer cleaning.
                    qty = np.random.choice(
                        [np.random.randint(1, 5), None],
                        p=[0.95, 0.05]
                    )

                    product_id = int(np.random.randint(1, 101))
                    unit_price = product_price_map[product_id]

                    lines.append({
                        "LineID": deterministic_uuid(),
                        "InvoiceID": invoice_id,
                        "ProductID": product_id,
                        "Quantity": qty,
                        "UnitPrice": unit_price
                    })

        current_date += timedelta(days=1)

    return pd.DataFrame(headers), pd.DataFrame(lines)


# ---------------------------------------------------------
# 3. INITIAL LOAD — JANUARY 2026
# ---------------------------------------------------------
print("Generating January 2026: INITIAL LOAD...")

initial_start = datetime(2026, 1, 1)
initial_end = datetime(2026, 2, 1)

initial_headers, initial_lines = generate_transactions(
    initial_start,
    initial_end
)

initial_headers.to_csv(
    os.path.join(initial_dir, "Invoices_Header.csv"),
    index=False
)

initial_lines.to_csv(
    os.path.join(initial_dir, "Invoices_Lines.csv"),
    index=False
)


# ---------------------------------------------------------
# 4. NEW TRANSACTIONS — FEBRUARY 2026
# ---------------------------------------------------------
print("Generating February 2026: NEW TRANSACTIONS...")

incremental_start = datetime(2026, 2, 1)
incremental_end = datetime(2026, 3, 1)

incremental_headers, incremental_lines = generate_transactions(
    incremental_start,
    incremental_end
)

incremental_headers.to_csv(
    os.path.join(incremental_dir, "Invoices_Header.csv"),
    index=False
)

incremental_lines.to_csv(
    os.path.join(incremental_dir, "Invoices_Lines.csv"),
    index=False
)


# ---------------------------------------------------------
# 5. CONTROLLED STATUS-UPDATE EVENTS
# ---------------------------------------------------------
def build_pending_updates(headers, random_seed, source_period):
    """
    Build deterministic status-change events for invoices created as Pending.

    85% -> Completed
    10% -> Cancelled
     5% -> remain Pending

    Important:
    This function does NOT modify the original Header CSV.
    It creates update events that will later be applied to SQL Server,
    so Fabric Mirroring can observe real UPDATE operations.
    """
    pending = headers.loc[
        headers["OrderStatus"] == "Pending",
        ["InvoiceID", "InvoiceDate", "OrderStatus"]
    ].copy()

    if pending.empty:
        return pd.DataFrame(
            columns=[
                "InvoiceID",
                "SourcePeriod",
                "OldStatus",
                "NewStatus",
                "ModifiedAt"
            ]
        )

    rng = np.random.default_rng(random_seed)

    # Shuffle deterministically before selecting transitions.
    pending = pending.iloc[
        rng.permutation(len(pending))
    ].reset_index(drop=True)

    total_pending = len(pending)
    completed_count = int(total_pending * PENDING_TO_COMPLETED)
    cancelled_count = int(total_pending * PENDING_TO_CANCELLED)

    completed_rows = pending.iloc[:completed_count].copy()
    cancelled_rows = pending.iloc[
        completed_count:completed_count + cancelled_count
    ].copy()

    completed_rows["NewStatus"] = "Completed"
    cancelled_rows["NewStatus"] = "Cancelled"

    updates = pd.concat(
        [completed_rows, cancelled_rows],
        ignore_index=True
    )

    updates["OldStatus"] = "Pending"
    updates["SourcePeriod"] = source_period

    modified_times = []

    if source_period == "January":
        # January Pending invoices are resolved at controlled times in February.
        for _ in range(len(updates)):
            modified_at = datetime(2026, 2, 1) + timedelta(
                days=int(rng.integers(0, 28)),
                hours=int(rng.integers(8, 22)),
                minutes=int(rng.integers(0, 59))
            )
            modified_times.append(modified_at)

    elif source_period == "February":
        # February Pending invoices can transition later in February.
        february_end = datetime(2026, 2, 28, 23, 59, 59)

        for invoice_date in pd.to_datetime(updates["InvoiceDate"]):
            modified_at = invoice_date.to_pydatetime() + timedelta(
                hours=int(rng.integers(1, 73))
            )

            if modified_at > february_end:
                modified_at = february_end

            modified_times.append(modified_at)

    else:
        raise ValueError(f"Unsupported source period: {source_period}")

    updates["ModifiedAt"] = [
        value.strftime("%Y-%m-%d %H:%M:%S")
        for value in modified_times
    ]

    return updates[
        [
            "InvoiceID",
            "SourcePeriod",
            "OldStatus",
            "NewStatus",
            "ModifiedAt"
        ]
    ]


print("Generating controlled February status-update events...")

january_updates = build_pending_updates(
    initial_headers,
    random_seed=SEED + 101,
    source_period="January"
)

february_updates = build_pending_updates(
    incremental_headers,
    random_seed=SEED + 202,
    source_period="February"
)

header_updates = pd.concat(
    [january_updates, february_updates],
    ignore_index=True
)

header_updates.to_csv(
    os.path.join(
        incremental_dir,
        "February_Header_Updates.csv"
    ),
    index=False
)


# ---------------------------------------------------------
# 6. VALIDATION
# ---------------------------------------------------------
print("Validating generated dataset...")

all_headers = pd.concat(
    [initial_headers, incremental_headers],
    ignore_index=True
)

all_lines = pd.concat(
    [initial_lines, incremental_lines],
    ignore_index=True
)

# Unique keys.
assert initial_headers["InvoiceID"].is_unique
assert incremental_headers["InvoiceID"].is_unique
assert all_headers["InvoiceID"].is_unique
assert all_lines["LineID"].is_unique
assert header_updates["InvoiceID"].is_unique

# Referential integrity.
assert all_lines["InvoiceID"].isin(all_headers["InvoiceID"]).all()
assert all_headers["StoreID"].isin(stores["StoreID"]).all()
assert all_lines["ProductID"].isin(products["ProductID"]).all()

# Product price consistency.
expected_prices = all_lines["ProductID"].map(product_price_map)

assert np.allclose(
    all_lines["UnitPrice"].astype(float),
    expected_prices.astype(float)
)

# Intentional data-quality issue must remain present.
assert all_lines["Quantity"].isna().sum() > 0

# New records must start with LastModifiedAt = InvoiceDate.
assert (
    pd.to_datetime(all_headers["LastModifiedAt"])
    == pd.to_datetime(all_headers["InvoiceDate"])
).all()

# Every update must target an existing Pending invoice.
base_status = all_headers.set_index("InvoiceID")["OrderStatus"]

assert header_updates["InvoiceID"].isin(base_status.index).all()

assert (
    base_status.loc[
        header_updates["InvoiceID"]
    ].eq("Pending")
).all()

# Every emitted event must be a real Pending -> terminal transition.
assert header_updates["OldStatus"].eq("Pending").all()
assert header_updates["NewStatus"].isin(
    ["Completed", "Cancelled"]
).all()

# ModifiedAt must be after the original InvoiceDate.
invoice_date_map = all_headers.set_index("InvoiceID")["InvoiceDate"]

original_dates = pd.to_datetime(
    invoice_date_map.loc[
        header_updates["InvoiceID"]
    ].to_numpy()
)

modified_dates = pd.to_datetime(
    header_updates["ModifiedAt"]
)

assert (modified_dates > original_dates).all()


# ---------------------------------------------------------
# 7. SUMMARY
# ---------------------------------------------------------
def print_status_distribution(label, headers):
    counts = headers["OrderStatus"].value_counts()
    percentages = (
        headers["OrderStatus"]
        .value_counts(normalize=True)
        .mul(100)
        .round(3)
    )

    print(f"\n{label} status distribution:")

    for status in STATUS_VALUES:
        print(
            f"  {status:9s}: "
            f"{counts.get(status, 0):,} "
            f"({percentages.get(status, 0):.3f}%)"
        )


print("\nGeneration and validation completed successfully.")

print("\nInitial Load — January:")
print(f"  Headers: {len(initial_headers):,}")
print(f"  Lines:   {len(initial_lines):,}")

print("\nIncremental Load — February:")
print(f"  Headers: {len(incremental_headers):,}")
print(f"  Lines:   {len(incremental_lines):,}")

print_status_distribution(
    "January",
    initial_headers
)

print_status_distribution(
    "February",
    incremental_headers
)

print("\nControlled February Header Updates:")
print(f"  January Pending transitions:  {len(january_updates):,}")
print(f"  February Pending transitions: {len(february_updates):,}")
print(f"  Total update events:          {len(header_updates):,}")

print(
    "\nIntentional NULL Quantity rows: "
    f"{all_lines['Quantity'].isna().sum():,}"
)

print(f"\nFiles created under: {output_dir}")
print("\nDATASET STATUS: VALIDATED — READY TO FREEZE")
