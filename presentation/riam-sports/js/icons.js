const ICONS = {
  grid: '<rect x="3.5" y="3.5" width="7" height="7" rx="1.6"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.6"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.6"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.6"/>',
  layers: '<path d="M12 3.5 20.5 8 12 12.5 3.5 8 12 3.5Z"/><path d="M3.5 12 12 16.5 20.5 12"/><path d="M3.5 16 12 20.5 20.5 16"/>',
  route: '<circle cx="6" cy="6" r="2.2"/><circle cx="18" cy="18" r="2.2"/><path d="M8 7.2c4.5.4 6.2 3.2 6.2 6.2"/><path d="M14 16.5 16.2 15.2 17.4 17.4"/>',
  phone: '<rect x="7" y="2.5" width="10" height="19" rx="2.2"/><path d="M11 18.5h2"/>',
  calendar: '<rect x="3.5" y="5" width="17" height="15" rx="2"/><path d="M3.5 9.5h17M8 3.5v3M16 3.5v3"/>',
  building: '<path d="M4 20.5V5.5A1.5 1.5 0 0 1 5.5 4h7A1.5 1.5 0 0 1 14 5.5v15"/><path d="M14 9.5h4.5A1.5 1.5 0 0 1 20 11v9.5"/><path d="M3 20.5h18M7 8h3M7 12h3M7 16h3"/>',
  tag: '<path d="M3.5 12.5V4.8A1.3 1.3 0 0 1 4.8 3.5h7.7L20.5 11.5 12.5 19.5 3.5 12.5Z"/><circle cx="8" cy="8" r="1.1" fill="currentColor" stroke="none"/>',
  clock: '<circle cx="12" cy="12" r="8.2"/><path d="M12 7.5V12l3 2"/>',
  card: '<rect x="3" y="5.5" width="18" height="13" rx="2"/><path d="M3 10h18M7 15h4"/>',
  bell: '<path d="M6 16.5V11a6 6 0 1 1 12 0v5.5l1.2 1.5H4.8L6 16.5Z"/><path d="M10 19a2 2 0 0 0 4 0"/>',
  shield: '<path d="M12 3.5 19 6.2v5.4c0 4.2-2.8 7.2-7 8.9-4.2-1.7-7-4.7-7-8.9V6.2L12 3.5Z"/>',
  columns: '<rect x="3.5" y="4" width="7" height="16" rx="1.5"/><rect x="13.5" y="4" width="7" height="16" rx="1.5"/>',
  list: '<path d="M9 7h11M9 12h11M9 17h11"/><path d="M4.5 7h.01M4.5 12h.01M4.5 17h.01"/>',
  cpu: '<rect x="6" y="6" width="12" height="12" rx="2"/><path d="M9 1.8v2.4M12 1.8v2.4M15 1.8v2.4M9 19.8v2.4M12 19.8v2.4M15 19.8v2.4M1.8 9h2.4M1.8 12h2.4M1.8 15h2.4M19.8 9h2.4M19.8 12h2.4M19.8 15h2.4"/>',
  flag: '<path d="M5 20.5V4"/><path d="M5 4.5h10.5l-1.6 3.2 1.6 3.3H5"/>',
  help: '<circle cx="12" cy="12" r="8.2"/><path d="M9.5 9.2a2.5 2.5 0 1 1 3.4 2.3c-.8.4-1.4 1-1.4 1.9V14"/><path d="M12 17h.01"/>',
  device: '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>',
  arrow: '<path d="M5 12h14M13 6l6 6-6 6"/>',
  check: '<path d="M5 12.5 9.2 17 19 7"/>',
  close: '<path d="M6 6l12 12M18 6 6 18"/>',
  map: '<path d="M12 21s6-5.1 6-10a6 6 0 1 0-12 0c0 4.9 6 10 6 10Z"/><circle cx="12" cy="11" r="1.7"/>',
  user: '<circle cx="12" cy="8" r="3"/><path d="M5.5 19.2a6.5 6.5 0 0 1 13 0"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  minus: '<path d="M5 12h14"/>',
  alert: '<path d="M12 4.2 21 19H3L12 4.2Z"/><path d="M12 10v4.2M12 16.8h.01"/>',
  lock: '<rect x="5.5" y="10.5" width="13" height="9" rx="1.6"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5"/>',
  download: '<path d="M12 4v10"/><path d="m8 10 4 4 4-4"/><path d="M5 19h14"/>',
  chevron: '<path d="m9 6 6 6-6 6"/>',
  filter: '<path d="M4 5h16l-6 7.2V19l-4 1.2v-8L4 5Z"/>',
  menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
  play: '<path d="M8 5.5v13l11-6.5L8 5.5Z"/>',
  google: '<circle cx="12" cy="12" r="8"/>',
  whatsapp: '<path d="M6 18.5 7.2 15A6.8 6.8 0 1 1 9.4 17.6L6 18.5Z"/>'
};

function icon(name) {
  return `<svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[name] || ""}</svg>`;
}

function sportIcon(id) {
  const paths = {
    badminton: '<path d="M14.5 4.2c2.8 2.2 3.2 6 .8 8.6L8.2 20"/><path d="M8 14.2c2.4-1 4.6-.4 6.2 1.2"/><path d="M7.2 19.2 5 21"/><circle cx="16.2" cy="6.2" r="1.1" fill="currentColor" stroke="none"/>',
    cricket: '<path d="M7 19.5 16.5 6.2"/><path d="m14.8 5.2 3.2 2.2-1.5 2.2-3.2-2.2 1.5-2.2Z"/><path d="M6.2 18.2 5 21"/>',
    basketball: '<circle cx="12" cy="12" r="8"/><path d="M4.2 12h15.6M12 4a12 12 0 0 1 0 16M12 4a12 12 0 0 0 0 16"/>',
    football: '<circle cx="12" cy="12" r="8"/><path d="m12 8 2.2 1.6-.8 2.6h-2.8L9.8 9.6 12 8Z"/><path d="M12 8V4.2M14.2 9.6 18 8M13.4 12.2 16.2 16M10.6 12.2 7.8 16M9.8 9.6 6 8"/>',
    pickleball: '<path d="M14.8 4.2 6.2 16.8"/><path d="m13.2 5.6 4.6 3.2-2.2 3.2-4.6-3.2 2.2-3.2Z"/><path d="M15.2 7.2h.01M16.4 8.6h.01M14.6 8.4h.01"/>',
    swimming: '<path d="M3 15c1.4 1.2 2.6 1.2 4 0s2.6-1.2 4 0 2.6 1.2 4 0 2.6-1.2 4 0"/><path d="M3 19c1.4 1.2 2.6 1.2 4 0s2.6-1.2 4 0 2.6 1.2 4 0 2.6-1.2 4 0"/><circle cx="8" cy="8" r="1.4"/><path d="M10.2 9.2c1.6 1 3.4.6 4.8-.8"/>'
  };
  return `<svg class="ico sport-ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[id] || ""}</svg>`;
}
