/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCkLjV0vwF0Ah46l7lvMKcAs2z0dUh94lc',
  authDomain: 'medaichain-19e32.firebaseapp.com',
  projectId: 'medaichain-19e32',
  storageBucket: 'medaichain-19e32.firebasestorage.app',
  messagingSenderId: '776552618546',
  appId: '1:776552618546:web:e44e915c66d14df90e3a2b',
  measurementId: 'G-2E17DGH0WW',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload?.notification?.title || 'MEDAIChain';
  const notificationOptions = {
    body: payload?.notification?.body || 'Nouvelle notification',
    icon: '/icons/Icon-192.png',
    data: payload?.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const targetUrl = '/#/login';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          client.focus();
          return;
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
      return null;
    }),
  );
});
