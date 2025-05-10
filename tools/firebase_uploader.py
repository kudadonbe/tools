# ---------------------------------------------
# tools/firebase_uploader.py
#
# Handles uploading data to Firestore using the Admin SDK.
#
# Author: Hussain Shareef (@kudadonbe)
# Date: 2025-03-26
# ---------------------------------------------

import json
import firebase_admin
from firebase_admin import credentials, firestore
import click
from config.settings import FIREBASE_KEY_PATH

# Firebase Initialization
if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_KEY_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()


def upload_single(collection_name: str, document_id: str, data: dict, dry_run: bool = False):
    if dry_run:
        print(f"[DRY RUN] Would upload: {document_id} to {collection_name}")
        return
    db.collection(collection_name).document(document_id).set(data)
    print(f"✅ Uploaded: {document_id} to {collection_name}")


def upload_bulk(collection_name: str, data_array: list, id_field: str = None, dry_run: bool = False):
    if dry_run:
        for item in data_array:
            doc_id = item.get(id_field) if id_field and id_field in item else "<auto-id>"
            print(f"[DRY RUN] Would upload: {doc_id} to {collection_name}")
        print(f"✅ [DRY RUN] Simulated upload of {len(data_array)} records.")
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
        list(db.collection("test").limit(1).stream())
        print("✅ Firebase connection is successful.")
        return True
    except Exception as e:
        print("❌ Firebase connection failed:", e)
        return False


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

    if file and collection:
        try:
            with open(file, "r", encoding="utf-8") as f:
                data = json.load(f)
            if not isinstance(data, list):
                raise ValueError("JSON data must be a list of objects.")
            upload_bulk(collection, data, id_field=id_field, dry_run=dry_run)
        except Exception as e:
            print(f"❌ Failed to process file: {e}")
    else:
        print("⚠️ Please provide both --file and --collection to upload data.")


if __name__ == "__main__":
    main()
