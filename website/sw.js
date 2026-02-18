const CACHE_NAME = 'scanner-offline-site-v2';

const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/privacy',
  '/terms',
  '/support',
  '/privacy.html',
  '/terms.html',
  '/support.html',
  '/styles.css',
  '/script.js',
  '/favicon.png',
  '/site.webmanifest',
  '/robots.txt',
  '/sitemap.xml',
  '/assets/logo-icon.png',
  '/assets/logo-full.png',
];

function normalizePath(pathname) {
  if (!pathname || pathname === '/index.html') {
    return '/';
  }

  if (pathname.endsWith('.html')) {
    const stripped = pathname.slice(0, -5);
    return stripped || '/';
  }

  return pathname;
}

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))))
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') {
    return;
  }

  const requestUrl = new URL(event.request.url);
  if (requestUrl.origin !== self.location.origin) {
    return;
  }

  const isNavigation = event.request.mode === 'navigate' || event.request.destination === 'document';

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE_NAME);

      if (isNavigation) {
        const normalizedPath = normalizePath(requestUrl.pathname);
        const normalizedUrl = `${normalizedPath}${requestUrl.search}`;

        const cachedPage = (await cache.match(normalizedUrl)) || (await cache.match(normalizedPath));
        if (cachedPage) {
          return cachedPage;
        }

        try {
          const networkPage = await fetch(normalizedUrl);
          if (networkPage && networkPage.status === 200 && networkPage.type === 'basic') {
            cache.put(normalizedUrl, networkPage.clone());
            cache.put(normalizedPath, networkPage.clone());
          }
          return networkPage;
        } catch {
          return (
            (await cache.match(normalizedPath)) ||
            (await cache.match('/')) ||
            (await cache.match('/index.html')) ||
            new Response('Offline', { status: 503, statusText: 'Offline' })
          );
        }
      }

      const cachedAsset = await cache.match(event.request);
      if (cachedAsset) {
        return cachedAsset;
      }

      try {
        const networkAsset = await fetch(event.request);
        if (networkAsset && networkAsset.status === 200 && networkAsset.type === 'basic') {
          cache.put(event.request, networkAsset.clone());
        }
        return networkAsset;
      } catch {
        return new Response('', { status: 504, statusText: 'Offline' });
      }
    })()
  );
});
