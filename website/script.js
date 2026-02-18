(function cookieConsent() {
  const banner = document.querySelector('[data-cookie-banner]');
  if (!banner) {
    return;
  }

  const consent = localStorage.getItem('scanner_cookie_consent');
  if (!consent) {
    banner.style.display = 'block';
  }

  const acceptBtn = banner.querySelector('[data-accept]');
  const rejectBtn = banner.querySelector('[data-reject]');

  function setConsent(value) {
    localStorage.setItem('scanner_cookie_consent', value);
    banner.style.display = 'none';
  }

  if (acceptBtn) {
    acceptBtn.addEventListener('click', function () {
      setConsent('accepted');
    });
  }

  if (rejectBtn) {
    rejectBtn.addEventListener('click', function () {
      setConsent('rejected');
    });
  }
})();

(function premiumUiInit() {
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const revealNodes = document.querySelectorAll('[data-aos]');
  if (!revealNodes.length) {
    return;
  }

  if (reducedMotion || !('IntersectionObserver' in window)) {
    revealNodes.forEach(function (node) {
      node.classList.add('is-inview');
    });
    return;
  }

  revealNodes.forEach(function (node) {
    const delayValue = Number.parseInt(node.getAttribute('data-aos-delay') || '0', 10);
    const durationValue = Number.parseInt(node.getAttribute('data-aos-duration') || '550', 10);
    if (Number.isFinite(delayValue) && delayValue >= 0) {
      node.style.transitionDelay = `${delayValue}ms`;
    }
    if (Number.isFinite(durationValue) && durationValue > 0) {
      node.style.transitionDuration = `${durationValue}ms`;
    }
  });

  const observer = new IntersectionObserver(
    function (entries, obs) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) {
          return;
        }
        entry.target.classList.add('is-inview');
        obs.unobserve(entry.target);
      });
    },
    {
      rootMargin: '0px 0px -8% 0px',
      threshold: 0.12,
    }
  );

  revealNodes.forEach(function (node) {
    observer.observe(node);
  });
})();

(function registerOfflineSupport() {
  if (!('serviceWorker' in navigator)) {
    return;
  }

  window.addEventListener('load', function () {
    navigator.serviceWorker.register('/sw.js').catch(function () {
      // Silent fail: the website still works without background caching.
    });
  });
})();
