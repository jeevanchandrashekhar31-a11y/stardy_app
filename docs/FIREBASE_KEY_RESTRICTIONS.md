# Firebase API Key Restrictions & Secrets Hygiene

This document provides clear, click-by-click instructions for restricting the Firebase API keys generated for the STARDY AI Flutter application (`stardy-ai-e555b`) in the Google Cloud Console.

> **CRITICAL SECURITY RULE:** Firebase service-account JSON files (the backend's Admin SDK private keys) must **NEVER** be added to this client repository. Backend credentials belong strictly on the backend server or in secret managers. Gitignore rules (`*service-account*.json` and `*-firebase-adminsdk-*.json`) prevent accidental commits.

---

### 1. Restrict the Android API Key
1. Open the [Google Cloud Console](https://console.cloud.google.com/).
2. Select your Firebase project: `stardy-ai-e555b`.
3. In the left navigation menu, go to **APIs & Services** > **Credentials**.
4. Under **API Keys**, select the API key associated with Android (`AIzaSyD62H7ohO52rqj7h4n0ioiSEKPOjkMmaoM`).
5. Under **Set application restrictions**, choose **Android apps**.
6. Click **Add an item**:
   - **Package name**: `com.stardyai.app`
   - **SHA-1 certificate fingerprint**: Enter your debug SHA-1 fingerprint (`fb4f6af03663906dfa6bef06acf270f6f3a1dde3`, also recorded in `google-services.json`), and later add your production release keystore SHA-1.
7. Click **Done**, then click **Save**.

---

### 2. Restrict the iOS API Key
1. In **APIs & Services** > **Credentials**, select the API key associated with iOS (`AIzaSyB0UP4yH5yUvTVF67ioDp0Qlv9Ltw5Pd2E`).
2. Under **Set application restrictions**, choose **iOS apps**.
3. Click **Add an item**:
   - **Bundle ID**: `com.stardyai.app`
4. Click **Done**, then click **Save**.

---

### 3. Browser Key
Leave the browser key alone for now. Web is not a mobile shipping target for this application.
