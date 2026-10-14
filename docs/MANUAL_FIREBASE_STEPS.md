# Manual Firebase Steps

This document outlines the required manual security steps for Jeevan in the Firebase and Google Cloud consoles following subphase F8.1.

### 1. Publish Deny-All Rules for Firestore and Storage
In the Firebase Console, navigate to Cloud Firestore > Rules, paste the contents of `firestore.rules`, and click "Publish". Next, navigate to Storage > Rules, paste the contents of `storage.rules`, and click "Publish" to enforce deny-all policies on both services.

### 2. Confirm Deny-All Rules in the Rules Playground
In the Firestore Rules tab, open the Rules Playground and run a simulated get or list request against any path to verify that read access is denied. Run simulated create or update requests in both the Firestore and Storage playgrounds to confirm that write operations are rejected as well.

### 3. Export and Delete Legacy Firestore User Documents
Once the backend database holds all migrated user data, use the Google Cloud Firestore export feature to back up legacy Firestore user records. After verifying your backup, delete any leftover user collections and documents from the Firestore Data tab to eliminate stale data.

### 4. Restrict Google API Key to Android Package and iOS Bundle ID
In Google Cloud Console, navigate to APIs & Services > Credentials and open the API key used by the Firebase project. Under Application restrictions, choose Android and iOS applications, then provide your Android package name (`com.stardyai.app`) with SHA-1 fingerprint and your iOS bundle identifier (`com.stardyai.app`) to prevent unauthorized key usage.
