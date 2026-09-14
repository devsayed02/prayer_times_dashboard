# Prayer Times Admin Dashboard

Prayer Times অ্যাপের জন্য Node.js + Express ভিত্তিক একটি server-rendered admin console। এটি browser-side Firebase Web SDK ব্যবহার করে না। Firebase Admin SDK এবং local `service-account.json` দিয়ে Firestore ও FCM access করে।

## Features

- Dashboard overview ও device analytics
- FCM topic/single-device notification এবং delivery history
- Islamic event CRUD
- App update policy ও promotional notice
- Bank/mobile payment method CRUD
- Qur’an reciter catalogue CRUD
- Supporter goal, stats ও verified purchase overview
- Light/dark theme এবং responsive layout

## Local setup

1. Firebase Console → Project settings → Service accounts → Firebase Admin SDK থেকে private key তৈরি করুন।
2. Download করা JSON file-টি project root-এ `service-account.json` নামে রাখুন। এই file Git দ্বারা ignore করা আছে।
3. `.env.example` কপি করে `.env` বানিয়ে প্রয়োজনমতো admin username/password দিন।
4. Run করুন:

   ```bash
   npm install
   npm start
   ```

5. Google Chrome-এ `http://127.0.0.1:3000` খুলুন।

Development-এ credentials না দিলে dashboard শুধু loopback/localhost request গ্রহণ করে। Production-এ `DASHBOARD_USERNAME` এবং `DASHBOARD_PASSWORD` বাধ্যতামূলক।

## Security

- `service-account.json`, `.env`, service-account variants এবং generated metadata Git-এ যাবে না।
- Admin credential কখনো frontend JavaScript-এ পাঠানো হয় না।
- Public Flutter app-এর `firestore.rules` পরিবর্তন করা হয় না; server-side Admin SDK আলাদা trusted boundary হিসেবে কাজ করে।
- Production deploy-এর সময় HTTPS reverse proxy ব্যবহার করুন।
