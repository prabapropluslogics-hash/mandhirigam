function badge(type) {
  const labels = { new: "NEW", enhance: "ENHANCEMENT", bug: "BUG FIX", existing: "EXISTING", ui: "UI ENHANCEMENT" };
  const tip = BADGE_TIPS[type] || "";
  return `<span class="badge badge-${type}" title="${esc(tip)}">${labels[type] || type}</span>`;
}

function sampleTag() {
  return '<span class="sample">Sample</span>';
}

function pill(value) {
  return `<span class="pill pill-${statusClass(value)}">${esc(value)}</span>`;
}

function pageHead(kicker, title, lede) {
  return `<header class="page-head"><p class="kicker">${kicker}</p><h1>${title}</h1>${lede ? `<p class="lede">${lede}</p>` : ""}</header>`;
}

function field(label, control, error) {
  return `<label class="field"><span>${label}</span>${control}${error ? `<small class="field-error">${error}</small>` : ""}</label>`;
}

function slotLegend() {
  const items = [
    ["available", "Available", "Open for a new booking"],
    ["booked", "Booked", "Already reserved"],
    ["past", "Past", "The time has passed"],
    ["closed", "Closed", "Outside hours or a weekly closure"],
    ["class", "Class", "Non-bookable teaching time"]
  ];
  return `<ul class="legend">${items.map(([id, label, why]) => `<li class="legend-${id}"><strong>${label}</strong><span>${why}</span></li>`).join("")}</ul>`;
}

function renderQuote(quote, compact) {
  if (!quote) return "";
  const lines = quote.lines.map((line) => `
    <div class="sum-line">
      <span>${esc(line.label)}${line.sample ? ` ${sampleTag()}` : ""}${line.note ? ` <em>${esc(line.note)}</em>` : ""}</span>
      <strong>${line.amount == null ? "—" : inr(line.amount)}</strong>
    </div>`).join("");
  return `
    <div class="quote ${compact ? "quote-compact" : ""}">
      ${lines}
      <div class="sum-line muted"><span>Taxes</span><strong title="Tax treatment is still a client decision">Pending confirmation</strong></div>
      <div class="sum-line total"><span>Final amount</span><strong>${quote.total == null ? "To be confirmed" : inr(quote.total)}</strong></div>
    </div>`;
}

function renderCalendar() {
  const selected = parseDate(state.draft.date);
  const cells = monthCells(selected.getFullYear(), selected.getMonth());
  const week = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const swimming = state.draft.sportId === "swimming" && state.draft.venueId === "saibaba";
  return `
    <div class="cal-head">
      <strong>${selected.toLocaleDateString("en-IN", { month: "long", year: "numeric" })}</strong>
      <div class="cal-nav">
        <button type="button" data-action="shift-month" data-dir="-1" aria-label="Previous month">${icon("chevron")}</button>
        <button type="button" data-action="shift-month" data-dir="1" aria-label="Next month">${icon("chevron")}</button>
      </div>
    </div>
    <div class="cal" role="grid" aria-label="Booking calendar">
      ${week.map((day) => `<span class="cal-dow">${day}</span>`).join("")}
      ${cells.map((date) => {
        if (!date) return '<span class="cal-empty"></span>';
        const key = dateKey(date);
        const closed = swimming && state.swim.closedDays.includes(date.getDay());
        const today = key === "2026-10-01";
        const pressed = key === state.draft.date;
        return `<button type="button" class="cal-day${closed ? " is-closed" : ""}${today ? " is-today" : ""}" data-action="pick-date" data-date="${key}" aria-pressed="${pressed}"><b>${date.getDate()}</b>${closed ? "<small>Closed</small>" : ""}</button>`;
      }).join("")}
    </div>`;
}

function renderDuration() {
  return `
    <div class="seg" role="group" aria-label="Booking duration">
      ${[30, 60, 90].map((mins) => {
        const label = mins === 30 ? "30 min" : mins === 60 ? "1 hour" : "1.5 hours";
        return `<button type="button" class="chip" data-action="set-duration" data-mins="${mins}" aria-pressed="${state.draft.duration === mins}">${label}</button>`;
      }).join("")}
    </div>`;
}

function renderModes() {
  const modes = MODES[state.draft.sportId] || [];
  return `
    <div class="mode-grid">
      ${modes.map((mode) => `
        <button type="button" class="mode-card" data-action="set-mode" data-mode="${mode.id}" aria-pressed="${state.draft.modeId === mode.id}">
          <span>${esc(mode.name)}</span>
          <strong>${esc(mode.priceLabel)}</strong>
          <small>${esc(mode.capacity)}</small>
        </button>`).join("")}
    </div>`;
}

function renderHeadcount() {
  const mode = modeById(state.draft.sportId, state.draft.modeId);
  if (!mode || mode.pricing !== "person") {
    return `<p class="quiet">This mode is priced for the court, not per person. Headcount is not required.</p>`;
  }
  const people = state.draft.headcount;
  const codeOpen = state.draft.sportId === "swimming" && people >= 8;
  return `
    <div class="stepper">
      <button type="button" data-action="headcount" data-dir="-1" aria-label="Fewer people">${icon("minus")}</button>
      <strong>${people}</strong>
      <button type="button" data-action="headcount" data-dir="1" aria-label="More people">${icon("plus")}</button>
      <span>people</span>
    </div>
    ${state.draft.sportId === "swimming" ? `<p class="quiet">${people >= 5 ? "Group rate applied: ₹300 per person." : "The ₹300 group rate starts at 5 people."}</p>` : `<p class="quiet">Badminton stays at ₹150 per person.</p>`}
    ${codeOpen ? `
      <div class="code-row">
        <input id="discount-code" data-bind="draft.discountCode" value="${esc(state.draft.discountCode)}" placeholder="Discount code" autocomplete="off" />
        <button type="button" class="btn secondary" data-action="apply-code">Apply</button>
      </div>
      ${state.draft.discountApplied ? `<p class="ok-text">RIAM8 applied. ${sampleTag()}</p>` : ""}
      ${state.draft.discountError ? `<small class="field-error">${esc(state.draft.discountError)}</small>` : `<small class="quiet">Walkthrough code: RIAM8. The ₹200 value is a sample until the client confirms the rule.</small>`}
    ` : state.draft.sportId === "swimming" ? `<p class="quiet">A discount code becomes available for a group of 8.</p>` : ""}`;
}

function renderSlotBoard() {
  const slots = getSlots();
  const closedDay = state.draft.sportId === "swimming" && state.draft.venueId === "saibaba" && state.swim.closedDays.includes(parseDate(state.draft.date).getDay());
  if (closedDay) {
    return `<div class="closed-banner"><strong>Wednesday · closed</strong><p>Saibaba swimming does not take rental bookings on Wednesday. The closure is a weekly rule, so the day stays visible with a reason.</p></div>`;
  }
  return `
    <div class="slot-grid">
      ${slots.map((slot) => {
        const open = slot.status === "available" || slot.status === "partial";
        const selected = state.draft.start === fmtMinutesKey(slot.start) && open;
        const price = open ? slotPriceLabel(slot) : slotStateLabel(slot.status);
        return `<button type="button" class="slot slot-${slot.status}${selected ? " is-selected" : ""}" data-action="pick-slot" data-start="${fmtMinutesKey(slot.start)}" data-status="${slot.status}" data-reason="${esc(slot.reason)}">
          <span class="slot-time">${fmtTime(slot.start)}</span>
          <span class="slot-state">${price}</span>
          <span class="slot-why">${esc(slot.reason)}</span>
        </button>`;
      }).join("")}
    </div>
    ${state.draft.explain ? `<div class="explain">${icon("alert")}<p>${esc(state.draft.explain)}</p></div>` : ""}`;
}

function fmtMinutesKey(total) {
  return `${pad(Math.floor(total / 60))}:${pad(total % 60)}`;
}

function slotStateLabel(status) {
  return { booked: "Booked", past: "Past", "past-booked": "Booked · past", closed: "Closed", class: "Class" }[status] || status;
}

function slotPriceLabel(slot) {
  if (slot.quote?.total == null) return "Rate pending";
  const mode = slot.quote.mode;
  if (mode?.pricing === "person") return `From ${inr(mode.rate)} / person`;
  return inr(slot.quote.total);
}

function renderSummaryBody() {
  const venue = venueById(state.draft.venueId);
  const sport = sportById(state.draft.sportId);
  const court = courtById(state.draft.courtId);
  const mode = modeById(state.draft.sportId, state.draft.modeId);
  const quote = currentQuote();
  const rows = [
    ["Venue", venue?.name],
    ["Sport", sport?.name],
    ["Court", court?.name],
    ["Date", fmtDate(state.draft.date)],
    ["Time", state.draft.start ? `${fmtTime(minutes(state.draft.start))} – ${fmtTime(minutes(state.draft.start) + state.draft.duration)}` : "Select a slot"],
    ["Duration", state.draft.duration === 30 ? "30 minutes" : state.draft.duration === 90 ? "1.5 hours" : "1 hour"],
    ["Booking mode", mode?.name || "—"],
    ["Headcount", mode?.pricing === "person" ? String(state.draft.headcount) : "Not required"]
  ];
  return `
    <dl class="facts">${rows.map(([label, value]) => `<div><dt>${label}</dt><dd>${esc(value || "—")}</dd></div>`).join("")}</dl>
    ${renderQuote(quote)}`;
}

function renderAuthPanel() {
  const draft = state.draft;
  return `
    <div class="auth-card">
      <button type="button" class="btn google" data-action="google-login">${icon("user")} Continue with Google</button>
      ${draft.authProvider === "google" ? `<p class="ok-text">Google sign-in selected. A verified mobile number is still required for WhatsApp.</p>` : ""}
      <div class="or">or</div>
      ${field("Phone number", `<div class="phone-row"><span>+91</span><input id="phone-input" inputmode="numeric" maxlength="10" placeholder="98430 11220" data-bind="draft.phone" value="${esc(draft.phone)}" /></div>`, draft.otpError && !draft.otpSent ? draft.otpError : "")}
      <button type="button" class="btn secondary wide" data-action="send-otp" ${draft.otpSending ? "disabled" : ""}>${draft.otpSending ? "Sending…" : draft.otpSent ? "Resend OTP" : "Send OTP"}</button>
      ${draft.otpSent ? `
        ${field("OTP", `<input id="otp-input" inputmode="numeric" maxlength="6" placeholder="6-digit code" data-bind="draft.otp" value="${esc(draft.otp)}" />`, draft.otpError)}
        <button type="button" class="btn wide" data-action="verify-otp">Verify</button>
        <p class="quiet">For this walkthrough the code is ${DEMO_OTP}.</p>
      ` : `<p class="quiet">WhatsApp reminders are sent to this number.</p>`}
      ${draft.authed && draft.authProvider === "otp" ? `<p class="ok-text">Mobile number verified.</p>` : ""}
    </div>`;
}

function selectOptions(items, value) {
  return items.map(([id, label]) => `<option value="${esc(id)}"${id === value ? " selected" : ""}>${esc(label)}</option>`).join("");
}

function renderBookingFilters() {
  const filter = state.bookingFilter;
  const courts = COURTS.filter((court) => (filter.venue === "all" || court.venueId === filter.venue) && (filter.sport === "all" || court.sportId === filter.sport));
  return `
    <div class="filters">
      <select data-filter="venue" aria-label="Filter by venue">${selectOptions([["all", "All venues"]].concat(VENUES.map((venue) => [venue.id, venue.name])), filter.venue)}</select>
      <select data-filter="sport" aria-label="Filter by sport">${selectOptions([["all", "All sports"]].concat(SPORTS.map((sport) => [sport.id, sport.name])), filter.sport)}</select>
      <select data-filter="court" aria-label="Filter by court">${selectOptions([["all", "All courts"]].concat(courts.map((court) => [court.id, court.name])), filter.court)}</select>
      <select data-filter="pay" aria-label="Filter by payment status">${selectOptions([["all", "All payments"], ["Paid", "Paid"], ["Pending", "Pending"], ["Processing", "Processing"], ["Failed", "Failed"], ["Refunded", "Refunded"]], filter.pay)}</select>
      <select data-filter="status" aria-label="Filter by booking status">${selectOptions([["all", "All booking statuses"], ["Confirmed", "Confirmed"], ["Pending", "Pending"], ["Completed", "Completed"], ["Hold", "Hold"], ["Cancelled", "Cancelled"]], filter.status)}</select>
      <input type="date" data-filter="date" value="${esc(filter.date)}" aria-label="Filter by date" />
      <input id="booking-search" type="search" placeholder="Search customer or ID" data-bind="bookingFilter.q" data-live="render" value="${esc(filter.q)}" />
    </div>`;
}

function renderBookingTable() {
  const rows = filteredBookings();
  if (!rows.length) {
    return `<div class="empty"><strong>No bookings match these filters.</strong><p>The scenario register still has every sample booking.</p><button type="button" class="btn secondary" data-action="clear-filters">Clear filters</button></div>`;
  }
  const head = ["Booking ID", "Customer", "Venue", "Sport", "Court", "Date", "Time", "Duration", "Mode", "People", "Amount", "Payment", "Status", "Created"];
  return `
    <div class="table-wrap">
      <table class="table">
        <thead><tr>${head.map((item) => `<th>${item}</th>`).join("")}</tr></thead>
        <tbody>
          ${rows.map((row) => `<tr>
            <td><strong>${esc(row.id)}</strong>${row.legacy ? `<div class="mini">Legacy reference</div>` : ""}</td>
            <td>${esc(row.customer)}</td>
            <td>${esc(venueById(row.venueId)?.name)}</td>
            <td>${esc(sportById(row.sportId)?.name)}</td>
            <td>${esc(courtById(row.courtId)?.name)}</td>
            <td>${esc(fmtDay(row.date))}</td>
            <td>${fmtTime(minutes(row.start))}</td>
            <td>${row.duration} min</td>
            <td>${esc(modeName(row))}</td>
            <td>${row.headcount || "—"}</td>
            <td>${row.amount == null ? "Pending" : inr(row.amount)}${row.sampleRate ? ` ${sampleTag()}` : ""}</td>
            <td>${pill(row.paymentStatus)}</td>
            <td>${pill(row.bookingStatus)}</td>
            <td>${esc(row.createdAt)}</td>
          </tr>`).join("")}
        </tbody>
      </table>
    </div>`;
}

function renderTxnTable() {
  const rows = filteredBookings().filter((row) => row.txn && row.txn !== "—");
  if (!rows.length) {
    return `<div class="empty"><strong>No transactions match these filters.</strong><p>Paid, failed, processing and refunded payments appear here.</p></div>`;
  }
  const head = ["Transaction", "Booking", "Customer", "Gateway", "Amount", "Payment", "Method", "Date", "Reference", "Refund"];
  return `
    <div class="table-wrap">
      <table class="table">
        <thead><tr>${head.map((item) => `<th>${item}</th>`).join("")}</tr></thead>
        <tbody>
          ${rows.map((row) => `<tr>
            <td><strong>${esc(row.txn)}</strong></td>
            <td>${esc(row.id)}</td>
            <td>${esc(row.customer)}</td>
            <td>${esc(row.gateway)}</td>
            <td>${row.amount == null ? "—" : inr(row.amount)}</td>
            <td>${pill(row.paymentStatus)}</td>
            <td>${esc(row.method)}</td>
            <td>${esc(row.createdAt)}</td>
            <td>${esc(row.txn)}</td>
            <td>${pill(row.refund === "None" ? "None" : row.refund)}</td>
          </tr>`).join("")}
        </tbody>
      </table>
    </div>`;
}

function renderCourtAdmin() {
  const venueId = state.pricingVenue;
  const courts = COURTS.filter((court) => court.venueId === venueId);
  return `
    <div class="inline-note">${icon("lock")}<p><strong>Deactivation preserves historical booking references.</strong> A court with past bookings is deactivated. The record stays so those bookings still resolve.</p></div>
    <div class="filters">
      <select data-action="pricing-venue" aria-label="Venue">${VENUES.map((venue) => `<option value="${venue.id}"${venue.id === venueId ? " selected" : ""}>${esc(venue.name)}</option>`).join("")}</select>
    </div>
    <div class="court-admin">
      ${courts.map((court) => {
        const inactive = isInactive(court);
        const history = allBookings().filter((booking) => booking.courtId === court.id).length || court.historicalBookings || 0;
        return `<article class="court-row${inactive ? " is-off" : ""}">
          <div>${sportIcon(court.sportId)}<div><strong>${esc(court.name)}</strong><span>${esc(sportById(court.sportId).name)} · ${history} linked booking${history === 1 ? "" : "s"}</span></div></div>
          <div class="row-actions">
            ${pill(inactive ? "Deactivated" : "Active")}
            ${court.legacy ? `<button type="button" class="btn secondary" data-action="explain-delete" data-court="${court.id}">Delete</button>` : `<button type="button" class="btn secondary" data-action="${inactive ? "activate-court" : "ask-deactivate"}" data-court="${court.id}">${inactive ? "Activate" : "Deactivate"}</button>`}
          </div>
        </article>`;
      }).join("")}
    </div>`;
}

function renderPricingAdmin() {
  const venueId = state.pricingVenue;
  const sportId = state.pricingSport;
  const bands = (BANDS[sportId] || {})[venueId] || [];
  const modes = MODES[sportId] || [];
  const courts = courtsFor(venueId, sportId, { includeInactive: true });
  const custom = state.customRules.filter((rule) => rule.venueId === venueId && rule.sportId === sportId);
  return `
    <div class="filters">
      <select data-action="pricing-venue" aria-label="Venue">${VENUES.map((venue) => `<option value="${venue.id}"${venue.id === venueId ? " selected" : ""}>${venue.name}</option>`).join("")}</select>
      <select data-action="pricing-sport" aria-label="Sport">${sportsAt(venueId, true).map((sport) => `<option value="${sport.id}"${sport.id === sportId ? " selected" : ""}>${sport.name}</option>`).join("")}</select>
    </div>
    <p class="quiet">Rates are stored against a venue and a time range. There is no single price that copies itself onto every venue.</p>
    <div class="rule-list">
      ${modes.filter((mode) => mode.pricing !== "band").map((mode) => `<article class="rule-card"><strong>${esc(mode.priceLabel)}</strong><span>${esc(mode.name)} · all courts at this venue</span></article>`).join("")}
      ${bands.map((band) => `<article class="rule-card"><strong>${inr(band.rate)} / hour ${band.sample ? sampleTag() : ""}</strong><span>${esc(band.label)} · ${esc(sportById(sportId).name)} · ${esc(venueById(venueId).name)}</span></article>`).join("")}
      ${custom.map((rule) => `<article class="rule-card"><strong>${inr(rule.price)} / hour</strong><span>${fmtTime(minutes(rule.start))} – ${fmtTime(minutes(rule.end))} · ${esc(rule.courtId === "all" ? "All courts" : courtById(rule.courtId)?.name)} · this session</span></article>`).join("")}
      ${!bands.length && modes.every((mode) => mode.pricing === "tbc") ? `<article class="rule-card"><strong>Rate to be confirmed</strong><span>Cricket net pricing is waiting on a client decision.</span></article>` : ""}
    </div>
    <form class="rule-form" data-action="add-rule">
      <h3>Add a time-band rule</h3>
      <div class="filters">
        <select name="court" aria-label="Court"><option value="all">All courts of this sport</option>${courts.map((court) => `<option value="${court.id}">${esc(court.name)}</option>`).join("")}</select>
        <select name="mode" aria-label="Booking mode"><option value="all">All modes</option>${modes.map((mode) => `<option value="${mode.id}">${esc(mode.name)}</option>`).join("")}</select>
        <input name="start" type="time" value="18:00" aria-label="Band starts" />
        <input name="end" type="time" value="21:00" aria-label="Band ends" />
        <input name="price" type="number" min="1" step="1" placeholder="Rate per hour" aria-label="Rate per hour" />
        <button class="btn" type="submit">Save rule</button>
      </div>
      ${state.ruleError ? `<small class="field-error">${esc(state.ruleError)}</small>` : ""}
    </form>`;
}

function renderBars(items) {
  const max = Math.max(...items.map((item) => item.value));
  return `<div class="bars">${items.map((item) => `<div class="bar-col"><span class="bar-value">${inr(item.value)}</span><div class="bar" style="height:${Math.max(8, (item.value / max) * 140)}px"></div><span>${item.label}</span></div>`).join("")}</div>`;
}

function renderSchedule(dayKind) {
  const blocks = dayKind === "sunday" ? state.swim.sunday : dayKind === "closed" ? [{ start: "00:00", end: "23:59", kind: "closed", label: "Completely closed" }] : state.swim.standard;
  return `<ol class="schedule">${blocks.map((block) => `<li class="sched-${block.kind}"><strong>${block.kind === "closed" ? "All day" : `${fmtTime(minutes(block.start))} – ${fmtTime(minutes(block.end))}`}</strong><span>${esc(block.label)}</span></li>`).join("")}</ol>`;
}

function whatsAppCard(booking) {
  const venue = venueById(booking.venueId);
  return `
    <article class="wa">
      <header>RIAM Sports</header>
      <p>Your RIAM Sports booking is confirmed.</p>
      <ul>
        <li>Booking ID: ${esc(booking.id)}</li>
        <li>Venue: ${esc(venue?.name)}</li>
        <li>Sport: ${esc(sportById(booking.sportId)?.name)}</li>
        <li>Court: ${esc(courtById(booking.courtId)?.name)}</li>
        <li>Date: ${esc(fmtDate(booking.date))}</li>
        <li>Time: ${fmtTime(minutes(booking.start))} · ${booking.duration} min</li>
        <li>Amount: ${booking.amount == null ? "Pending" : inr(booking.amount)}</li>
      </ul>
      <p>Directions: the stored Google Maps link for ${esc(venue?.name)}.</p>
    </article>`;
}

function bindAssign(path, value) {
  const [root, key] = path.split(".");
  if (state[root]) state[root][key] = value;
}
