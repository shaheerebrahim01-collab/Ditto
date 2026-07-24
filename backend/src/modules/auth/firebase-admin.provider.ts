import * as admin from 'firebase-admin';

// Firebase Admin needs to be initialized exactly once. This lazily creates
// it from env vars the first time it's used, and reuses it after that —
// so importing this file never has side effects until you actually call it.
let app: admin.app.App | undefined;

export function getFirebaseAdmin(): admin.app.App {
  if (!app) {
    app = admin.apps.length
      ? (admin.apps[0] as admin.app.App)
      : admin.initializeApp({
          credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            // Env vars store newlines as literal "\n" — turn them back into
            // real line breaks or the private key won't parse.
            privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
          }),
        });
  }
  return app;
}
