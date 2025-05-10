# ---------------------------------------------
# config/settings.py - Project Configuration
#
# Defines global configuration variables and environment settings
# for the KDM Tools project.
#
# Author: Hussain Shareef (@kudadonbe)
# Date: 2025-03-26
# ---------------------------------------------

import os
from dotenv import load_dotenv

# Load environment variables from a .env file if available
load_dotenv()

# Path to Firebase Admin SDK key (JSON file)
FIREBASE_KEY_PATH = os.getenv("FIREBASE_KEY", "config/firebase-key.json")
