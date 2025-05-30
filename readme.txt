# EchoRemind

A context-aware reminder application that triggers notifications based on your location (arrival or departure).

## Overview

EchoRemind helps you stay on top of your tasks by reminding you at the right place and time. Set reminders linked to specific locations, and the app will notify you when you arrive or leave those areas.

This MVP currently includes:

* Location-based reminders (geofencing).
* Local storage of reminders using SQLite.
* Local notifications.
* In-app purchase integration for premium features.

## Features

* Create reminders with a title and a location.
* Set reminders to trigger on arrival or departure from a location.
* View a list of active and inactive reminders.
* Google Maps integration for easy location selection.
* Background geofencing for reliable triggering.
* Local notifications to alert you.
* Premium features (custom sounds, more than 5 reminders, adjustable geofence radius) available via in-app subscription.

## Getting Started

1.  **Clone the repository:**
    ```bash
    # If you initialize an empty git repo, then manually create files, this step is skipped.
    # Otherwise, assuming you get this from a git repo:
    git clone [repository_url]
    cd echo_remind
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Set up platform configurations:**
    * **Android:** Ensure you have the necessary SDKs and configure `AndroidManifest.xml` for location and notification permissions. Remember to set your actual app package name.
    * **iOS:** Configure `Info.plist` with the required location and notification usage descriptions.
4.  **Replace Placeholder API Keys:** Update `'YOUR_REVENUECAT_APP_ID'` in `lib/services/purchase/purchase_service.dart` with your actual RevenueCat App ID.
5.  **Add your app icon:** Place your `app_icon.png` in `android/app/src/main/res/drawable` and configure iOS assets in Xcode.
6.  **Run the app:**
    ```bash
    flutter run
    ```

## Directory Structure

