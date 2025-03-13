Online Radio Player
A Flutter-based desktop application for streaming online radio stations. This app allows users to browse and play radio stations, control playback, adjust volume, and dynamically update the API endpoint for fetching stations. It also includes an image carousel for visual appeal.

Features
Stream Radio Stations: Play online radio stations fetched from a configurable API endpoint.

Dynamic API Endpoint: Update the API endpoint via a settings screen.

Playback Controls: Play, pause, skip to the next station, and go back to the previous station.

Volume Control: Adjust volume using a slider or buttons.

Image Carousel: Displays a rotating carousel of images.

Persistent Settings: Save the API endpoint using shared_preferences.

Responsive UI: Designed for desktop with a clean and intuitive interface.
API Endpoint Format
The app expects the API endpoint to return a JSON array of radio stations in the following format:
[
  {
    "id": 1,
    "created_at": "2024-11-22T21:21:41.100293+00:00",
    "name": "xxxx",
    "url": "http://sstream"
  },
  {
    "id": 2,
    "created_at": "2024-11-22T21:22:06.879202+00:00",
    "name": " v fm",
    "url": "https://stream2"
  }
]
