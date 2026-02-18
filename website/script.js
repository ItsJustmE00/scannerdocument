(function () {
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
