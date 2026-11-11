# Tracker

A minimal habit and number tracker for iPhone, with home screen and lock screen widgets.
Filled dot = done. Ring = not done. Orange = today.

## Run it (5 minutes)

1. On your Mac, download this repository (green **Code** button → **Download ZIP**) and unzip it.
2. Double-click **Tracker.xcodeproj**. It opens in Xcode.
3. At the top of the Xcode window, pick an iPhone simulator (for example **iPhone 17**).
4. Press the **Play** button (or `Cmd + R`). The app starts in the simulator.

## Put it on your own iPhone

1. In Xcode, click the blue **Tracker** icon at the top of the left sidebar.
2. Select the **Tracker** target → **Signing & Capabilities** → choose your **Team** (your Apple ID).
3. Do the same for the **TrackerWidgetExtension** target.
4. Plug in your iPhone, pick it at the top of the window, and press **Play**.

If Xcode says the bundle identifier is taken: click the blue **Tracker** icon → the **Tracker** *project* → **Build Settings** → search `APP_BUNDLE_ID` → change it to something of your own (for example `com.yourname.tracker`). That one setting updates the app, the widget and the shared data group together.

With a free Apple ID the app stops opening after 7 days; press Play again to renew it.

## Add the widgets

Long-press the home screen → **Edit** → **Add Widget** → search **Tracker**.

| Widget | Size | Shows |
| --- | --- | --- |
| Tracker | Small | One tracker, this week's dots, tap to log |
| Today | Medium | Your first three trackers, tap each to log |
| Tracker | Large | The whole year in dots |
| Tracker | Lock screen | Count, or this week's dots |

To change which tracker a widget shows: long-press the widget → **Edit Widget**.

## Using the app

- **Day / Week / Month / Year**: tap the words at the top, or swipe sideways.
- **Log**: tap the circle on a row. Done trackers toggle; number trackers add one step.
- **Exact amount or note**: tap the tracker's name.
- **Fix a past day**: tap that day's dot in Week or Month.
- **New tracker**: bottom of the Day screen.
- **Edit or delete**: tap a tracker's name → **Edit tracker**.

The app starts with five example trackers (Gym, Water, Steps, Calories, Spent). Change or delete them freely.

## Where things are

| Folder | What it holds |
| --- | --- |
| `Tracker/` | The app's screens |
| `TrackerWidget/` | The widgets |
| `Shared/` | Data, colors and the dot, used by both |
| `Config/` | Signing files; no need to touch |

Data is saved on the phone only. No account, no server.

Requires Xcode 16 or later and iOS 17 or later.
