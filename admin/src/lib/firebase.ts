import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

// Same "ditto-713d5" project as customer_app/tailor_app — Firebase Auth is
// project-wide, not per-registered-app, so this web config (already
// registered for customer_app's web build) works here unchanged. This is a
// public client identifier, not a secret, which is why it's committed
// directly rather than pulled from an env var — same convention the
// Flutter apps' firebase_options.dart already follows.
const firebaseConfig = {
  apiKey: 'AIzaSyCssgF3G_afAzRVG3V9pkbZruWN_2RIM-Y',
  authDomain: 'ditto-713d5.firebaseapp.com',
  projectId: 'ditto-713d5',
  storageBucket: 'ditto-713d5.firebasestorage.app',
  messagingSenderId: '209876187617',
  appId: '1:209876187617:web:3a6576d4bda25c7595faa0',
  measurementId: 'G-3RZ2NG52MB',
};

export const firebaseApp = initializeApp(firebaseConfig);
export const firebaseAuth = getAuth(firebaseApp);
