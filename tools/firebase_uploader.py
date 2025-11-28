# ---------------------------------------------
# tools/firebase_uploader.py
#
# Handles uploading data to Firestore using the Admin SDK.
#
# Author: Hussain Shareef (@kudadonbe)
# Date: 2025-03-26
# ---------------------------------------------

import json
import click
from pathlib import Path
import firebase_admin
from firebase_admin import credentials, firestore
from config.settings import FIREBASE_KEY_PATH

try:
    import tkinter as tk
    from tkinter import filedialog
except ImportError:
    tk = None

# Firebase Initialization
if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_KEY_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()


def upload_single(collection_name: str, document_id: str = None, data: dict = None, dry_run: bool = False):
    if dry_run:
        print(f"[DRY RUN] Would upload to collection '{collection_name}'")
        print(f" - Document ID: {document_id or '<auto-id>'}")
        print(f" - Data:\n{json.dumps(data, indent=2)}")
        return
    db.collection(collection_name).document(document_id).set(data) if document_id else db.collection(collection_name).add(data)
    print(f"✅ Uploaded: {document_id or '<auto-id>'} to {collection_name}")


def upload_bulk(collection_name: str, data_array: list, id_field: str = None, dry_run: bool = False):
    if dry_run:
        print(f"[DRY RUN] Would upload {len(data_array)} document(s) to collection '{collection_name}':")
        for i, item in enumerate(data_array, start=1):
            doc_id = item.get(id_field) if id_field and id_field in item else "<auto-id>"
            print(f"\n📝 Document {i}:")
            print(f" - Document ID: {doc_id}")
            print(f" - Data:\n{json.dumps(item, indent=2)}")
        print(f"\n✅ [DRY RUN] Completed simulation for {len(data_array)} documents.")
        return

    batch = db.batch()
    for item in data_array:
        doc_id = item.get(id_field) if id_field and id_field in item else None
        ref = db.collection(collection_name).document(doc_id) if doc_id else db.collection(collection_name).document()
        batch.set(ref, item)
    batch.commit()
    print(f"✅ Bulk upload completed for {len(data_array)} records to {collection_name}")



def test_connection() -> bool:
    try:
        docs = db.collection("test").limit(5).stream()
        print("✅ Firebase connection is successful.")
        for doc in docs:
            data = doc.to_dict()
            name = data.get("name", "[no name field]")
            print(f" - Found document with name: {name}")
        return True
    except Exception as e:
        print("❌ Firebase connection failed:", e)
        return False


def pick_json_file_gui() -> str:
    if tk is None:
        raise RuntimeError("tkinter is not available on this system.")
    root = tk.Tk()
    root.withdraw()
    file_path = filedialog.askopenfilename(
        title="Select a JSON file",
        filetypes=[("JSON files", "*.json")],
    )
    return file_path


@click.command()
@click.option('--test', is_flag=True, help="Run Firebase connection test.")
@click.option('--file', type=click.Path(exists=True), help="Path to JSON data file.")
@click.option('--collection', type=str, help="Target Firestore collection name.")
@click.option('--id-field', type=str, default=None, help="Field name to use as document ID.")
@click.option('--dry-run', is_flag=True, help="Simulate upload without writing to Firestore.")
def main(test, file, collection, id_field, dry_run):
    if test:
        test_connection()
        return

    # If no file is provided, show file picker
    if not file:
        print("📂 No file provided. Opening file picker...")
        file = pick_json_file_gui()
        if not file:
            print("⚠️ No file selected. Exiting.")
            return

    # Read and determine collection name and data type
    try:
        with open(file, "r", encoding="utf-8") as f:
            data = json.load(f)

        collection_name = collection or Path(file).stem

        if isinstance(data, list):
            print(f"📤 Uploading collection '{collection_name}' with {len(data)} records...")
            upload_bulk(collection_name, data, id_field=id_field, dry_run=dry_run)

        elif isinstance(data, dict):
            print(f"📤 Uploading single document to collection '{collection_name}'...")
            upload_single(collection_name, data=data, dry_run=dry_run)

        else:
            raise ValueError("JSON must be a list of objects or a single object.")

    except Exception as e:
        print(f"❌ Failed to process file: {e}")


if __name__ == "__main__":
    main()
