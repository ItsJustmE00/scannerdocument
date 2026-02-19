(function mobileHeaderMenu() {
  const header = document.querySelector('.site-header');
  if (!header) {
    return;
  }

  const toggle = header.querySelector('[data-menu-toggle]');
  const panel = header.querySelector('[data-header-menu]');
  if (!toggle || !panel) {
    return;
  }

  const desktopQuery = window.matchMedia('(min-width: 761px)');

  function setMenuOpen(isOpen) {
    const open = Boolean(isOpen);
    header.classList.toggle('is-menu-open', open);
    toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    toggle.setAttribute('aria-label', open ? 'Fermer le menu' : 'Ouvrir le menu');
    toggle.textContent = open ? 'Fermer' : 'Menu';
  }

  setMenuOpen(false);

  toggle.addEventListener('click', function () {
    const open = header.classList.contains('is-menu-open');
    setMenuOpen(!open);
  });

  panel.querySelectorAll('a').forEach(function (link) {
    link.addEventListener('click', function () {
      if (!desktopQuery.matches) {
        setMenuOpen(false);
      }
    });
  });

  const themeToggle = panel.querySelector('[data-theme-toggle]');
  if (themeToggle) {
    themeToggle.addEventListener('click', function () {
      if (!desktopQuery.matches) {
        setTimeout(function () {
          setMenuOpen(false);
        }, 60);
      }
    });
  }

  document.addEventListener('click', function (event) {
    if (desktopQuery.matches) {
      return;
    }
    if (!header.contains(event.target)) {
      setMenuOpen(false);
    }
  });

  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
      setMenuOpen(false);
    }
  });

  const onViewportChange = function (event) {
    if (event.matches) {
      setMenuOpen(false);
    }
  };

  if (typeof desktopQuery.addEventListener === 'function') {
    desktopQuery.addEventListener('change', onViewportChange);
  } else if (typeof desktopQuery.addListener === 'function') {
    desktopQuery.addListener(onViewportChange);
  }
})();

(function themeModeToggle() {
  const storageKey = 'scanner_theme_mode';
  const root = document.documentElement;
  const toggle = document.querySelector('[data-theme-toggle]');
  const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

  function readStoredMode() {
    try {
      const value = localStorage.getItem(storageKey);
      return value === 'dark' || value === 'light' ? value : null;
    } catch {
      return null;
    }
  }

  function writeStoredMode(mode) {
    try {
      localStorage.setItem(storageKey, mode);
    } catch {
      // Ignore storage failures.
    }
  }

  function getSystemMode() {
    return mediaQuery.matches ? 'dark' : 'light';
  }

  function applyMode(mode, persistMode) {
    const effectiveMode = mode === 'dark' ? 'dark' : 'light';
    root.setAttribute('data-theme', effectiveMode);

    if (persistMode) {
      writeStoredMode(effectiveMode);
    }

    if (!toggle) {
      return;
    }

    const isDark = effectiveMode === 'dark';
    const iconNode = toggle.querySelector('[data-theme-icon]');
    const labelNode = toggle.querySelector('[data-theme-label]');

    if (iconNode) {
      iconNode.textContent = isDark ? 'D' : 'L';
    }

    if (labelNode) {
      labelNode.textContent = isDark ? 'Mode sombre' : 'Mode clair';
    }

    toggle.setAttribute('aria-pressed', isDark ? 'true' : 'false');
    toggle.setAttribute('title', isDark ? 'Passer en mode clair' : 'Passer en mode sombre');
  }

  const savedMode = readStoredMode();
  applyMode(savedMode || getSystemMode(), false);

  if (toggle) {
    toggle.addEventListener('click', function () {
      const currentMode = root.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
      applyMode(currentMode === 'dark' ? 'light' : 'dark', true);
    });
  }

  const onSystemModeChange = function (event) {
    if (readStoredMode()) {
      return;
    }
    applyMode(event.matches ? 'dark' : 'light', false);
  };

  if (typeof mediaQuery.addEventListener === 'function') {
    mediaQuery.addEventListener('change', onSystemModeChange);
  } else if (typeof mediaQuery.addListener === 'function') {
    mediaQuery.addListener(onSystemModeChange);
  }
})();

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
    navigator.serviceWorker
      .register('/sw.js')
      .then(function (registration) {
        registration.update();
      })
      .catch(function () {
        // Silent fail: the website still works without background caching.
      });
  });
})();
