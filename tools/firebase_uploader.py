# tools/firebase_uploader.py

import os
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Firebase Initialization
if not firebase_admin._apps:
    cred = credentials.Certificate(os.getenv("FIREBASE_KEY_PATH"))
    firebase_admin.initialize_app(cred)

db = firestore.client()

def upload_single(collection_name: str, document_id: str, data: dict):
    """
    Upload a single document to Firestore.
    """
    db.collection(collection_name).document(document_id).set(data)
    print(f"✅ Uploaded: {document_id} to {collection_name}")

def upload_bulk(collection_name: str, data_array: list, id_field: str = None):
    """
    Upload a list of documents to Firestore.
    If `id_field` is specified, it's used as the document ID.
    """
    batch = db.batch()
    for item in data_array:
        doc_id = item[id_field] if id_field and id_field in item else None
        ref = db.collection(collection_name).document(doc_id) if doc_id else db.collection(collection_name).document()
        batch.set(ref, item)
    batch.commit()
    print(f"✅ Bulk upload completed for {len(data_array)} records to {collection_name}")
