const icons = {
  arrow: '<path d="M4 12h15m-6-6 6 6-6 6"/>',
  grid: '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/>',
  scan: '<path d="M8 3H5a2 2 0 0 0-2 2v3m13-5h3a2 2 0 0 1 2 2v3M3 16v3a2 2 0 0 0 2 2h3m13-5v3a2 2 0 0 1-2 2h-3M4 12h16"/>',
  bell: '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9m-8 12a2 2 0 0 0 4 0"/>',
  ticket: '<path d="M4 5h16a1 1 0 0 1 1 1v3a3 3 0 0 0 0 6v3a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-3a3 3 0 0 0 0-6V6a1 1 0 0 1 1-1Zm11 0v2m0 4v2m0 4v2"/>',
  chart: '<path d="M4 4v16h16M9 15v-3m5 3V8m5 7V5"/>',
  activity: '<path d="M3 12h4l3-7 4 14 3-7h4"/>',
  sliders: '<path d="M4 7h6m4 0h6M4 17h10m4 0h2"/><circle cx="12" cy="7" r="2"/><circle cx="16" cy="17" r="2"/>',
  user: '<circle cx="12" cy="8" r="3"/><path d="M5 20v-1a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v1"/>',
  logout: '<path d="M11 4H5v16h6m4-12 4 4-4 4m-6-4h10"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  refresh: '<path d="M20 10a8 8 0 0 0-14-4l-2 3m0-5v5h5m-5 5a8 8 0 0 0 14 4l2-3m0 5v-5h-5"/>',
  external: '<path d="M13 4h7v7m0-7-9 9m7 0v6H5V6h6"/>',
  usb: '<path d="M12 21V3m-3 3 3-3 3 3m-3 9-5-4V8m5 9 5-4v-2"/><circle cx="7" cy="7" r="1"/><rect x="16" y="9" width="2" height="2"/>',
  sparkle: '<path d="M12 3c1 5 4 8 9 9-5 1-8 4-9 9-1-5-4-8-9-9 5-1 8-4 9-9Z"/>',
  close: '<path d="m6 6 12 12m0-12L6 18"/>',
  download: '<path d="M12 3v12m-5-5 5 5 5-5M4 16v4h16v-4"/>',
};

export function renderIcons() {
  for (const target of document.querySelectorAll('[data-icon]')) {
    const drawing = icons[target.dataset.icon];
    if (!drawing) continue;
    target.setAttribute('aria-hidden', 'true');
    target.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' + drawing + '</svg>';
  }
}
