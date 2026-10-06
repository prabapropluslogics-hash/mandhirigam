const NOW = new Date(2026, 9, 1, 13, 13, 0);
const DEMO_OTP = "482913";
const DEMO_CODE = "RIAM8";

function pad(n) {
  return String(n).padStart(2, "0");
}

function esc(value) {
  return String(value ?? "").replace(/[&<>"']/g, (ch) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;"
  }[ch]));
}

function inr(amount) {
  if (amount == null || Number.isNaN(amount)) return "Pending";
  const rounded = Math.round(amount);
  const sign = rounded < 0 ? "−" : "";
  return `${sign}₹${Math.abs(rounded).toLocaleString("en-IN")}`;
}

function minutes(hhmm) {
  const [h, m] = String(hhmm).split(":").map(Number);
  return h * 60 + m;
}

function fmtTime(total) {
  const mins = ((total % (24 * 60)) + 24 * 60) % (24 * 60);
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  const hr = h % 12 || 12;
  return `${hr}:${pad(m)} ${h >= 12 ? "PM" : "AM"}`;
}

function fmtDate(key) {
  const d = parseDate(key);
  return d.toLocaleDateString("en-IN", { weekday: "short", day: "numeric", month: "short", year: "numeric" });
}

function fmtDay(key) {
  const d = parseDate(key);
  return d.toLocaleDateString("en-IN", { day: "numeric", month: "short" });
}

function parseDate(key) {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d);
}

function dateKey(date) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

function venueById(id) {
  return VENUES.find((venue) => venue.id === id);
}

function sportById(id) {
  return SPORTS.find((sport) => sport.id === id);
}

function courtById(id) {
  return COURTS.find((court) => court.id === id);
}

function modeById(sportId, modeId) {
  return (MODES[sportId] || []).find((mode) => mode.id === modeId) || null;
}

function isInactive(court) {
  if (!court) return true;
  return court.legacy || state.inactiveIds.includes(court.id);
}

function allBookings() {
  return state.extraBookings.concat(BOOKINGS);
}

function sportsAt(venueId, includeLegacy) {
  const ids = COURTS.filter((court) => court.venueId === venueId && (includeLegacy || !court.legacy)).map((court) => court.sportId);
  return SPORTS.filter((sport) => ids.includes(sport.id));
}

function courtsFor(venueId, sportId, opts = {}) {
  return COURTS.filter((court) => {
    if (venueId && court.venueId !== venueId) return false;
    if (sportId && court.sportId !== sportId) return false;
    if (!opts.includeLegacy && court.legacy) return false;
    if (!opts.includeInactive && isInactive(court)) return false;
    return true;
  });
}

function activeCourtCount() {
  return COURTS.filter((court) => !isInactive(court)).length;
}

function cloneSwim() {
  return JSON.parse(JSON.stringify(DEFAULT_SWIM));
}

function swimBlocks(dateStr) {
  const day = parseDate(dateStr).getDay();
  if (state.swim.closedDays.includes(day)) return [{ start: "00:00", end: "23:59", kind: "closed", label: "Closed for the day" }];
  return day === 0 ? state.swim.sunday : state.swim.standard;
}

function blockAt(dateStr, minute, sportId, venueId) {
  if (!(sportId === "swimming" && venueId === "saibaba")) return { kind: "open" };
  const blocks = swimBlocks(dateStr);
  const block = blocks.find((item) => minute >= minutes(item.start) && minute < minutes(item.end));
  if (!block) {
    return { kind: "closed", label: "Outside operating hours", reason: "This time is outside the swimming rental hours." };
  }
  if (block.kind === "closed") {
    return { kind: "closed", label: "Closed", reason: "Swimming at Saibaba is closed every Wednesday." };
  }
  if (block.kind === "class") {
    return { kind: "class", label: "Class", reason: `Swimming class · ${fmtTime(minutes(block.start))} – ${fmtTime(minutes(block.end))}. Not available for rental.` };
  }
  return { kind: "open", label: block.label };
}

function slotWindow(sportId, venueId) {
  if (sportId === "swimming" && venueId === "saibaba") return { from: 8 * 60, to: 23 * 60 };
  return { from: state.showOvernight ? 0 : 6 * 60, to: 24 * 60 };
}

function overlaps(a0, a1, b0, b1) {
  return a0 < b1 && b0 < a1;
}

function blockingBookings(courtId, dateStr) {
  return allBookings().filter((booking) => (
    booking.courtId === courtId &&
    booking.date === dateStr &&
    booking.bookingStatus !== "Cancelled" &&
    booking.bookingStatus !== "Hold" &&
    booking.paymentStatus !== "Failed"
  ));
}

function occupancy(courtId, dateStr, start, end, modeId) {
  const hits = blockingBookings(courtId, dateStr).filter((booking) => overlaps(start, end, minutes(booking.start), minutes(booking.end)));
  if (!hits.length) return null;
  if (modeId === "half") {
    if (hits.some((booking) => booking.modeId === "full")) {
      return { state: "booked", reason: "Full court is already reserved for this time." };
    }
    const sides = new Set(hits.filter((booking) => booking.modeId === "half").map((booking) => booking.side || "A"));
    if (sides.size >= 2) return { state: "booked", reason: "Both halves of this court are already booked." };
    const taken = [...sides][0];
    return { state: "partial", reason: `Half court, side ${taken}, is booked. The other side is still open.` };
  }
  if (modeId === "full" && hits.length) {
    return { state: "booked", reason: hits.some((booking) => booking.modeId === "half") ? "A half-court booking already holds part of this court." : "This court is already reserved." };
  }
  if (modeId === "private") return { state: "booked", reason: "The pool already has a booking in this time." };
  if (modeId === "person") {
    if (hits.some((booking) => booking.modeId === "private")) {
      return { state: "booked", reason: "The pool is privately reserved for this time." };
    }
    const people = hits.filter((booking) => booking.modeId === "person").reduce((sum, booking) => sum + (booking.headcount || 0), 0);
    if (people > 0) return { state: "partial", reason: `${people} people are already booked. Shared entry is still open.` };
  }
  return { state: "booked", reason: `Reserved by ${hits[0].customer}.` };
}

function isPastSlot(dateStr, start) {
  const day = parseDate(dateStr);
  const slotStart = new Date(day.getFullYear(), day.getMonth(), day.getDate(), 0, start);
  return slotStart <= NOW;
}

function getSlots() {
  const draft = state.draft;
  const window = slotWindow(draft.sportId, draft.venueId);
  const step = draft.duration === 60 ? 60 : 30;
  const slots = [];
  for (let start = window.from; start + draft.duration <= window.to; start += step) {
    const end = start + draft.duration;
    const probes = [];
    for (let cursor = start; cursor < end; cursor += 15) probes.push(cursor);
    const blocks = probes.map((minute) => blockAt(draft.date, minute, draft.sportId, draft.venueId));
    let status = "available";
    let reason = "Open for booking.";
    const classBlock = blocks.find((block) => block.kind === "class");
    const closedBlock = blocks.find((block) => block.kind === "closed");
    if (classBlock) {
      status = "class";
      reason = classBlock.reason;
    } else if (closedBlock) {
      status = "closed";
      reason = closedBlock.reason || "The venue is closed for this time.";
    } else {
      const held = occupancy(draft.courtId, draft.date, start, end, draft.modeId);
      if (held && held.state === "booked") {
        status = "booked";
        reason = held.reason;
      } else if (held && held.state === "partial") {
        status = "partial";
        reason = held.reason;
      }
    }
    const past = isPastSlot(draft.date, start);
    if (past && status === "booked") {
      status = "past-booked";
      reason = "This time has passed. It was reserved.";
    } else if (past && status !== "closed" && status !== "class") {
      status = "past";
      reason = "This time has already passed.";
    }
    slots.push({ start, end, status, reason, quote: quoteFor(start, draft.duration) });
  }
  return slots;
}

function bandAt(sportId, venueId, minute) {
  const bands = (BANDS[sportId] || {})[venueId];
  if (!bands) return null;
  return bands.find((band) => minute >= band.start && minute < band.end) || null;
}

function rateAt(minute) {
  const draft = state.draft;
  const custom = state.customRules.find((rule) => (
    rule.venueId === draft.venueId &&
    rule.sportId === draft.sportId &&
    (rule.courtId === "all" || rule.courtId === draft.courtId) &&
    (rule.modeId === "all" || rule.modeId === draft.modeId) &&
    minute >= minutes(rule.start) &&
    minute < minutes(rule.end)
  ));
  if (custom) return { rate: Number(custom.price), sample: false, custom: true, label: "Session rule" };
  const mode = modeById(draft.sportId, draft.modeId);
  if (mode && mode.pricing === "hourly") return { rate: mode.rate, sample: false, label: mode.name };
  const band = bandAt(draft.sportId, draft.venueId, minute);
  if (band) return { rate: band.rate, sample: band.sample, label: band.label };
  return null;
}

function quoteFor(start, duration, draftOverride) {
  const draft = draftOverride || state.draft;
  const previous = state.draft;
  if (draftOverride) state.draft = draftOverride;
  const mode = modeById(draft.sportId, draft.modeId);
  let result;
  if (!mode) {
    result = { total: null, lines: [], sample: false, mode: null };
  } else if (mode.pricing === "tbc") {
    result = { total: null, lines: [{ label: "Net rental rate", amount: null, note: "To be confirmed" }], sample: false, mode };
  } else if (mode.pricing === "session") {
    result = { total: mode.rate, lines: [{ label: `${mode.name} session`, amount: mode.rate }], sample: false, mode };
  } else if (mode.pricing === "person") {
    const people = Math.max(1, Number(draft.headcount) || 1);
    const group = draft.sportId === "swimming" && people >= 5;
    const rate = group ? 300 : mode.rate;
    const lines = [{ label: `${inr(mode.rate)} × ${people}`, amount: mode.rate * people }];
    if (group) lines.push({ label: "Group rate for 5 or more", amount: (rate - mode.rate) * people });
    let codeOff = 0;
    if (draft.sportId === "swimming" && people >= 8 && draft.discountApplied) {
      codeOff = 200;
      lines.push({ label: "Discount code RIAM8", amount: -codeOff, sample: true });
    }
    result = { total: rate * people - codeOff, lines, sample: codeOff > 0, mode, rate, people, group };
  } else {
    const lines = [];
    let cursor = start;
    const end = start + duration;
    while (cursor < end) {
      const chunkEnd = Math.min(end, Math.floor(cursor / 30) * 30 + 30);
      const safeEnd = chunkEnd <= cursor ? cursor + (end - cursor) : Math.min(end, chunkEnd);
      const rated = rateAt(cursor);
      const length = safeEnd - cursor;
      if (!rated) {
        lines.push({ label: `${fmtTime(cursor)} – ${fmtTime(safeEnd)}`, amount: null, note: "Rate to be confirmed" });
      } else {
        lines.push({
          label: `${fmtTime(cursor)} – ${fmtTime(safeEnd)} · ${inr(rated.rate)} / hour`,
          amount: rated.rate * length / 60,
          sample: rated.sample,
          custom: rated.custom
        });
      }
      cursor = safeEnd;
    }
    const merged = [];
    lines.forEach((line) => {
      const last = merged[merged.length - 1];
      if (last && last.sample === line.sample && last.custom === line.custom && last.label.split("·")[1] === line.label.split("·")[1] && last.amount != null && line.amount != null) {
        last.amount += line.amount;
        const startLabel = last.label.split("–")[0];
        const endLabel = line.label.split("–")[1];
        last.label = `${startLabel}– ${endLabel}`;
      } else merged.push({ ...line });
    });
    const total = merged.some((line) => line.amount == null) ? null : merged.reduce((sum, line) => sum + line.amount, 0);
    result = { total, lines: merged, sample: merged.some((line) => line.sample), mode };
  }
  if (draftOverride) state.draft = previous;
  return result;
}

function currentQuote() {
  if (!state.draft.start) return quoteFor(18 * 60, state.draft.duration);
  return quoteFor(minutes(state.draft.start), state.draft.duration);
}

function syncDraft() {
  const draft = state.draft;
  const sports = sportsAt(draft.venueId);
  if (!sports.some((sport) => sport.id === draft.sportId)) draft.sportId = sports[0]?.id || "pickleball";
  const courts = courtsFor(draft.venueId, draft.sportId);
  if (!courts.some((court) => court.id === draft.courtId)) draft.courtId = courts[0]?.id || "";
  const modes = MODES[draft.sportId] || [];
  if (!modes.some((mode) => mode.id === draft.modeId)) draft.modeId = modes[0]?.id || "";
  if (draft.headcount < 1) draft.headcount = 1;
}

function monthCells(year, month) {
  const first = new Date(year, month, 1);
  const padCount = (first.getDay() + 6) % 7;
  const days = new Date(year, month + 1, 0).getDate();
  const cells = Array.from({ length: padCount }, () => null);
  for (let day = 1; day <= days; day += 1) cells.push(new Date(year, month, day));
  return cells;
}

function isMapsUrl(value) {
  try {
    const url = new URL(String(value).trim());
    if (url.protocol !== "https:") return false;
    return /(^|\.)google\.[a-z.]+$/i.test(url.hostname) || url.hostname === "maps.app.goo.gl" || url.hostname === "goo.gl";
  } catch {
    return false;
  }
}

function filteredBookings() {
  const filter = state.bookingFilter;
  return allBookings().filter((booking) => {
    if (filter.venue !== "all" && booking.venueId !== filter.venue) return false;
    if (filter.sport !== "all" && booking.sportId !== filter.sport) return false;
    if (filter.court !== "all" && booking.courtId !== filter.court) return false;
    if (filter.pay !== "all" && booking.paymentStatus !== filter.pay) return false;
    if (filter.status !== "all" && booking.bookingStatus !== filter.status) return false;
    if (filter.date && booking.date !== filter.date) return false;
    if (filter.q) {
      const hay = `${booking.id} ${booking.customer} ${booking.txn}`.toLowerCase();
      if (!hay.includes(filter.q.toLowerCase())) return false;
    }
    return true;
  });
}

function scenarioMetrics() {
  const rows = allBookings();
  const paid = rows.filter((row) => row.paymentStatus === "Paid");
  return {
    total: rows.length,
    today: rows.filter((row) => row.date === "2026-10-01").length,
    revenue: paid.reduce((sum, row) => sum + (row.amount || 0), 0),
    venues: VENUES.length,
    courts: activeCourtCount(),
    pending: rows.filter((row) => row.paymentStatus === "Pending" || row.paymentStatus === "Processing").length
  };
}

function modeName(booking) {
  return modeById(booking.sportId, booking.modeId)?.name || "Rental";
}

function statusClass(value) {
  if (["Paid", "Confirmed", "Completed", "Active", "Success"].includes(value)) return "ok";
  if (["Pending", "Processing", "Hold"].includes(value)) return "warn";
  if (["Failed", "Cancelled", "Refunded"].includes(value)) return "bad";
  return "mute";
}

function loadSession() {
  try {
    return JSON.parse(localStorage.getItem("riam-review-session") || "{}");
  } catch {
    return {};
  }
}

function saveSession() {
  try {
    localStorage.setItem("riam-review-session", JSON.stringify({
      decisions: state.decisions,
      apiFields: state.apiFields
    }));
  } catch {
    /* The review still works if storage is blocked. */
  }
}

const saved = loadSession();

const state = {
  route: "overview",
  navOpen: false,
  presentation: false,
  slide: 0,
  journey: 0,
  venueTab: "hierarchy",
  treeSport: "badminton",
  mounted: false,
  inactiveIds: [],
  extraBookings: [],
  customRules: [],
  showOvernight: false,
  swim: cloneSwim(),
  razorpayMode: "test",
  payPreview: "success",
  maps: Object.fromEntries(VENUES.map((venue) => [venue.id, venue.mapsUrl])),
  mapsError: {},
  decisions: saved.decisions || Object.fromEntries(DECISIONS.map((item) => [item.id, item.status])),
  apiFields: saved.apiFields || Object.fromEntries(API_FIELDS.map(([id]) => [id, true])),
  bookingFilter: { venue: "all", sport: "all", court: "all", pay: "all", status: "all", date: "", q: "" },
  trackerFilter: "all",
  pricingVenue: "thudiyalur",
  pricingSport: "pickleball",
  bugChecked: true,
  fixChecked: false,
  bugNote: "",
  modal: null,
  toast: "",
  toastArmed: false,
  proto: "login",
  adminNotice: "",
  ruleError: "",
  draft: {
    venueId: "thudiyalur",
    sportId: "basketball",
    courtId: "td-bb-1",
    date: "2026-10-04",
    start: "19:00",
    duration: 60,
    modeId: "full",
    headcount: 5,
    discountCode: "",
    discountApplied: false,
    discountError: "",
    phone: "",
    otp: "",
    otpSent: false,
    otpError: "",
    otpSending: false,
    authed: false,
    authProvider: "",
    payment: "idle",
    explain: "",
    bookingId: ""
  }
};
