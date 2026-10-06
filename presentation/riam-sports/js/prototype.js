function viewPrototype() {
  const customer = PROTO_SCREENS.filter((screen) => screen[2] === "customer");
  const admin = PROTO_SCREENS.filter((screen) => screen[2] === "admin");
  const lane = state.proto.startsWith("admin") ? "admin" : "customer";
  return `
    <section class="page proto-page">
      ${pageHead("UI prototype", "A clickable walkthrough of the customer app and the admin tools.", "Use the screen list to jump, or move through the product the way a customer or a venue manager would.")}
      <div class="presenter-bar">
        <div class="seg">
          <button type="button" class="chip" data-action="proto" data-screen="home" aria-pressed="${lane === "customer"}">Customer</button>
          <button type="button" class="chip" data-action="proto" data-screen="admin-home" aria-pressed="${lane === "admin"}">Admin</button>
        </div>
        <label>Prototype screens
          <select data-action="proto-select" aria-label="Prototype screens">
            <optgroup label="Customer">${customer.map(([id, label]) => `<option value="${id}"${state.proto === id ? " selected" : ""}>${esc(label)}</option>`).join("")}</optgroup>
            <optgroup label="Admin">${admin.map(([id, label]) => `<option value="${id}"${state.proto === id ? " selected" : ""}>${esc(label)}</option>`).join("")}</optgroup>
          </select>
        </label>
      </div>
      <div class="product ${lane}">
        ${lane === "customer" ? customerChrome(customerScreen()) : adminChrome(adminScreen())}
      </div>
    </section>`;
}

function customerChrome(body) {
  const tabs = [["home", "Home"], ["location", "Book"], ["history", "Bookings"], ["venue", "Venue"]];
  return `
    <div class="app-frame">
      <header class="app-top"><span class="mark">R</span><strong>RIAM Sports</strong><em>${esc(venueById(state.draft.venueId).name)}</em></header>
      <div class="app-body">${body}</div>
      <nav class="app-tab">${tabs.map(([id, label]) => `<button type="button" data-action="proto" data-screen="${id}" aria-pressed="${state.proto === id}">${label}</button>`).join("")}</nav>
    </div>`;
}

function customerScreen() {
  const screens = {
    login: screenLogin,
    home: screenHome,
    location: screenLocation,
    sport: screenSport,
    court: screenCourt,
    calendar: screenCalendar,
    slots: screenSlots,
    mode: screenMode,
    headcount: screenHead,
    summary: screenSummary,
    payment: screenPayment,
    success: screenSuccess,
    history: screenHistory,
    venue: screenVenue
  };
  return (screens[state.proto] || screenHome)();
}

function screenLogin() {
  return `<div class="screen"><h2>Welcome back</h2><p class="quiet">Sign in to book a court. WhatsApp updates use your mobile number.</p>${renderAuthPanel()}<button type="button" class="btn wide" data-action="proto" data-screen="home">Continue to venues</button></div>`;
}

function screenHome() {
  const next = allBookings().find((row) => row.customer === "Arun Kumar" && row.bookingStatus === "Confirmed");
  return `
    <div class="screen">
      <p class="kicker">Good afternoon</p>
      <h2>${state.draft.authed ? "Ready when you are" : "Book a court"}</h2>
      <article class="upcoming"><span>Upcoming</span><strong>${esc(next.id)}</strong><p>${esc(sportById(next.sportId).name)} · ${esc(courtById(next.courtId).name)} · ${esc(fmtDay(next.date))}</p></article>
      <h3>Venues</h3>
      <div class="stack">${VENUES.map((venue) => `<button type="button" class="choice" data-action="choose-venue" data-venue="${venue.id}" data-next="sport"><strong>${esc(venue.name)}</strong><span>${esc(venue.hours)}</span></button>`).join("")}</div>
    </div>`;
}

function screenLocation() {
  return `<div class="screen"><h2>Select a location</h2><div class="stack">${VENUES.map((venue) => `<button type="button" class="choice" data-action="choose-venue" data-venue="${venue.id}" data-next="sport"><strong>${esc(venue.name)}</strong><span>${esc(venue.address)}</span></button>`).join("")}</div></div>`;
}

function screenSport() {
  const sports = sportsAt(state.draft.venueId);
  return `<div class="screen"><h2>${esc(venueById(state.draft.venueId).name)}</h2><p class="quiet">Sports offered at this venue.</p><div class="sport-picks big">${sports.map((sport) => `<button type="button" data-action="choose-sport" data-sport="${sport.id}">${sportIcon(sport.id)}<span>${esc(sport.name)}</span></button>`).join("")}</div></div>`;
}

function screenCourt() {
  const courts = courtsFor(state.draft.venueId, state.draft.sportId);
  return `<div class="screen"><h2>Select a court</h2><p class="quiet">${esc(sportById(state.draft.sportId).name)} · each court has its own calendar.</p><div class="stack">${courts.map((court) => `<button type="button" class="choice" data-action="choose-court" data-court="${court.id}"><strong>${esc(court.name)}</strong><span>Next open times are on this court’s calendar</span></button>`).join("")}</div></div>`;
}

function screenCalendar() {
  return `<div class="screen"><h2>Select a date</h2><p class="quiet">${esc(courtById(state.draft.courtId)?.name || "")}</p>${renderCalendar()}<button type="button" class="btn wide" data-action="proto" data-screen="slots">View slots</button></div>`;
}

function screenSlots() {
  return `<div class="screen"><h2>Available time</h2>${renderDuration()}${slotLegend()}${renderSlotBoard()}<button type="button" class="btn wide" data-action="proto" data-screen="mode">Continue</button></div>`;
}

function screenMode() {
  return `<div class="screen"><h2>Booking mode</h2>${renderModes()}<button type="button" class="btn wide" data-action="proto-after-mode">Continue</button></div>`;
}

function screenHead() {
  return `<div class="screen"><h2>How many people?</h2>${renderHeadcount()}${renderQuote(currentQuote(), true)}<button type="button" class="btn wide" data-action="proto" data-screen="summary">Review price</button></div>`;
}

function screenSummary() {
  const needsPhone = !/^\d{10}$/.test(state.draft.phone);
  return `<div class="screen"><h2>Price summary</h2>${renderSummaryBody()}${needsPhone ? `<p class="field-error">Add a 10-digit mobile number before payment so the WhatsApp confirmation has a destination.</p><div class="phone-row"><span>+91</span><input id="summary-phone" inputmode="numeric" maxlength="10" data-bind="draft.phone" value="${esc(state.draft.phone)}" /></div>` : `<p class="ok-text">WhatsApp will use +91 ${esc(state.draft.phone)}.</p>`}<button type="button" class="btn wide" data-action="go-pay">Proceed to payment</button></div>`;
}

function screenPayment() {
  if (state.draft.payment === "processing") return `<div class="screen pay-card"><div class="spinner"></div><strong>Processing</strong><p>Contacting Razorpay ${state.razorpayMode === "test" ? "test" : "live preview"}.</p></div>`;
  if (state.draft.payment === "failed") return `<div class="screen pay-card failed"><strong>Payment failed</strong><p>No booking was confirmed. You can try the payment again.</p><button type="button" class="btn wide" data-action="pay-now">Try again</button></div>`;
  const quote = currentQuote();
  return `<div class="screen"><h2>Razorpay</h2><p class="quiet">${state.razorpayMode === "test" ? "Test mode. Production keys are not loaded in this review." : "Live badge preview. The merchant account is not actually switched."}</p><div class="pay-card"><strong>${quote.total == null ? "Amount pending" : inr(quote.total)}</strong><span>${esc(venueById(state.draft.venueId).name)} · ${esc(courtById(state.draft.courtId)?.name || "")}</span></div><button type="button" class="btn wide" data-action="pay-now">Pay now</button><button type="button" class="btn secondary wide" data-action="pay-fail">Preview a failed payment</button></div>`;
}

function screenSuccess() {
  const booking = allBookings().find((row) => row.id === state.draft.bookingId) || {
    id: state.draft.bookingId || "RIAM-10601",
    venueId: state.draft.venueId,
    sportId: state.draft.sportId,
    courtId: state.draft.courtId,
    date: state.draft.date,
    start: state.draft.start || "19:00",
    duration: state.draft.duration,
    amount: currentQuote().total
  };
  return `
    <div class="screen success-screen">
      <p class="success-mark">${icon("check")}</p>
      <h2>Payment successful</h2>
      <dl class="facts">
        <div><dt>Booking ID</dt><dd>${esc(booking.id)}</dd></div>
        <div><dt>Venue</dt><dd>${esc(venueById(booking.venueId).name)}</dd></div>
        <div><dt>Sport</dt><dd>${esc(sportById(booking.sportId).name)}</dd></div>
        <div><dt>Court</dt><dd>${esc(courtById(booking.courtId)?.name)}</dd></div>
        <div><dt>Date</dt><dd>${esc(fmtDate(booking.date))}</dd></div>
        <div><dt>Time</dt><dd>${fmtTime(minutes(booking.start))}</dd></div>
        <div><dt>Amount</dt><dd>${booking.amount == null ? "Pending" : inr(booking.amount)}</dd></div>
      </dl>
      <button type="button" class="btn wide" data-action="proto" data-screen="history">View booking</button>
      <button type="button" class="btn secondary wide" data-action="download">Download confirmation</button>
    </div>`;
}

function screenHistory() {
  const mine = allBookings().filter((row) => row.customer === "Arun Kumar" || row.id === state.draft.bookingId);
  if (!mine.length) return `<div class="screen empty"><strong>No bookings yet.</strong><p>A confirmed payment will appear here.</p></div>`;
  return `<div class="screen"><h2>Booking history</h2><div class="stack">${mine.map((row) => `<article class="choice static"><strong>${esc(row.id)}</strong><span>${esc(sportById(row.sportId).name)} · ${esc(courtById(row.courtId)?.name)} · ${esc(fmtDay(row.date))}</span><em>${esc(row.bookingStatus)} · ${esc(row.paymentStatus)}</em></article>`).join("")}</div></div>`;
}

function screenVenue() {
  const venue = venueById(state.draft.venueId);
  return `<div class="screen"><h2>${esc(venue.name)}</h2><p>${esc(venue.address)}</p><p class="quiet">${esc(venue.hours)}</p><button type="button" class="btn wide" data-action="directions" data-venue="${venue.id}">${icon("map")} Get Directions</button><button type="button" class="btn secondary wide" data-action="proto" data-screen="sport">Book here</button></div>`;
}

function adminChrome(body) {
  const items = [["admin-home", "Dashboard"], ["admin-venues", "Venues"], ["admin-courts", "Courts"], ["admin-pricing", "Pricing"], ["admin-availability", "Availability"], ["admin-bookings", "Bookings"], ["admin-transactions", "Transactions"], ["admin-reports", "Reports"]];
  return `<div class="admin-frame"><aside>${items.map(([id, label]) => `<button type="button" data-action="proto" data-screen="${id}" aria-pressed="${state.proto === id}">${label}</button>`).join("")}</aside><div class="admin-main">${body}</div></div>`;
}

function adminScreen() {
  const screens = {
    "admin-home": screenAdminHome,
    "admin-venues": screenAdminVenues,
    "admin-courts": screenAdminCourts,
    "admin-pricing": screenAdminPricing,
    "admin-availability": screenAdminAvailability,
    "admin-bookings": screenAdminBookings,
    "admin-transactions": screenAdminTx,
    "admin-reports": screenAdminReports
  };
  return (screens[state.proto] || screenAdminHome)();
}

function screenAdminHome() {
  const metrics = scenarioMetrics();
  const cards = [["Total bookings", metrics.total], ["Today’s bookings", metrics.today], ["Revenue", inr(metrics.revenue)], ["Active venues", metrics.venues], ["Active courts", metrics.courts], ["Pending payments", metrics.pending]];
  return `<div class="screen"><h2>Today at RIAM</h2><div class="metric-strip">${cards.map(([label, value]) => `<article><span>${label}</span><strong>${value}</strong></article>`).join("")}</div><div class="module-grid compact">${ADMIN_MODULES.slice(0, 8).map(([title, text]) => `<button type="button" class="mod" data-action="admin-jump" data-title="${esc(title)}"><strong>${title}</strong><span>${text}</span></button>`).join("")}</div></div>`;
}

function screenAdminVenues() {
  return `<div class="screen"><h2>Venues</h2>${VENUES.map((venue) => `<article class="venue-link"><header><strong>${esc(venue.name)}</strong><span>${esc(venue.address)}</span></header>${field("Google Maps URL", `<input id="admin-maps-${venue.id}" data-bind="maps.${venue.id}" value="${esc(state.maps[venue.id])}" />`, state.mapsError[venue.id] || "")}<div class="hero-actions"><button type="button" class="btn" data-action="save-map" data-venue="${venue.id}">Save</button><button type="button" class="btn secondary" data-action="directions" data-venue="${venue.id}">Open link</button></div></article>`).join("")}</div>`;
}

function screenAdminCourts() {
  return `<div class="screen"><h2>Courts</h2><p class="quiet">New courts are assigned to a sport and a venue. Deactivation keeps the record.</p>${renderCourtAdmin()}</div>`;
}

function screenAdminPricing() {
  return `<div class="screen"><h2>Pricing</h2>${renderPricingAdmin()}</div>`;
}

function screenAdminAvailability() {
  return `<div class="screen"><h2>Availability and hours</h2><p class="quiet">Saibaba swimming, with the Wednesday closure and class blocks.</p><button type="button" class="chip" data-action="toggle-wednesday" aria-pressed="${state.swim.closedDays.includes(3)}">${state.swim.closedDays.includes(3) ? "Wednesday closed" : "Wednesday open in this preview"}</button><h3>Weekdays except Sunday</h3>${renderSchedule("standard")}<h3>Sunday</h3>${renderSchedule("sunday")}</div>`;
}

function screenAdminBookings() {
  return `<div class="screen"><h2>Bookings</h2>${renderBookingFilters()}${renderBookingTable()}</div>`;
}

function screenAdminTx() {
  return `<div class="screen"><h2>Transactions</h2><p class="quiet">Booking reads should be able to return these payment fields once the list is confirmed.</p>${renderTxnTable()}</div>`;
}

function screenAdminReports() {
  return `<div class="screen"><h2>Reports</h2><p class="quiet">Illustrative collections for 22–28 Sep 2026. ${sampleTag()}</p>${renderBars(REVENUE)}<p class="quiet">Saturday is the strongest day in this sample week. Use the booking register for the named scenario records.</p></div>`;
}

PAGES.prototype = viewPrototype;
