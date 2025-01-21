importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "TU-API-KEY",
  authDomain: "TU-AUTH-DOMAIN",
  projectId: "TU-PROJECT-ID",
  storageBucket: "TU-STORAGE-BUCKET",
  messagingSenderId: "TU-MESSAGING-SENDER-ID",
  appId: "TU-APP-ID"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Received background message:', payload);
});