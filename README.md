# AlzDetect Flutter Frontend

This project is a Flutter UI for your Alzheimer detection backend (`app.py`).

## 1) Generate platform folders (first time only)
If this folder is new, run:

```bash
flutter create .
```

Then run:

```bash
flutter pub get
```

## 2) Set backend URL
Edit:
- `lib/config.dart`

Change `baseUrl` to your Flask backend URL.

Examples:
- Android emulator: `http://10.0.2.2:5000`
- Same machine desktop/web: `http://127.0.0.1:5000`
- Real phone: `http://<YOUR_PC_LAN_IP>:5000`

## 3) Backend endpoint expected
The app sends `POST /predict` as multipart form data with:
- `file` (MRI image)
- `patient_id`
- `patient_name`
- `age`
- `gender`

## 4) Run app
```bash
flutter run
```

## Response JSON supported
The UI can read these fields if present:
- `diagnosis` or `prediction` or `result`
- `confidence`
- `risk_score`
- `recommendation`

