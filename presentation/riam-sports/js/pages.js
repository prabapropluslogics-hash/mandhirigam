function viewOverview() {
  const metrics = [
    ["Sports", "6", "Configured activities"],
    ["Venues", "2", "Thudiyalur and Saibaba"],
    ["Bookable courts", String(activeCourtCount()), "Independent calendars"],
    ["Booking modes", "4", "Half, full, person, private"],
    ["Payment gateway", "Razorpay", state.razorpayMode === "test" ? "Test mode today" : "Live preview"],
    ["Notifications", "WhatsApp", "Booking updates and reminders"]
  ];
  return `
    <section class="page">
      ${pageHead("Client review · October 2026", "RIAM Sports Booking Platform", "Centralized sports venue discovery, court booking and management. The approved scope already covers discovery, hourly booking, Razorpay, Google login and admin operations. This review separates that platform from the court-level model now requested.")}
      <div class="hero-grid">
        <div class="hero-copy">
          <div class="flag-row"><span class="flag">${badge("existing")}<span>Core platform</span></span><span class="flag">${badge("new")}<span>Change request</span></span></div>
          <p>Customers should be able to book a specific court, see why a time is unavailable, and pay a price that follows the venue, the hour, the mode and the number of people.</p>
          <div class="hero-actions">
            <button type="button" class="btn" data-action="present">${icon("play")} Start presentation</button>
            <button type="button" class="btn secondary" data-action="nav" data-id="prototype">Open the prototype</button>
          </div>
        </div>
        <aside class="read-card">
          <h2>How to read the status labels</h2>
          <ul>
            <li>${badge("existing")} Already in the approved document.</li>
            <li>${badge("enhance")} The idea exists and the implementation has to go further.</li>
            <li>${badge("bug")} Current behaviour needs a correction.</li>
            <li>${badge("new")} A requirement the original document does not define.</li>
          </ul>
        </aside>
      </div>
      <div class="metric-strip">${metrics.map(([label, value, note]) => `<article><span>${label}</span><strong>${value}</strong><small>${note}</small></article>`).join("")}</div>
      <section class="block">
        <div class="block-head"><h2>How a booking moves</h2><p>From the customer to a confirmed court reservation.</p></div>
        <ol class="flow">${FLOW.map((step, index) => `<li><span>${pad(index + 1)}</span>${esc(step)}</li>`).join("")}</ol>
      </section>
      <section class="block">
        <div class="block-head"><h2>The three areas that need a timeline</h2><p>The client asked for rough timelines on these. They are structural changes, not small corrections. Day counts stay open until technical validation.</p></div>
        <div class="three">${TIMELINE.map((item) => `<article><span class="num">${item.n}</span><h3>${esc(item.title)}</h3><p>${esc(item.note)}</p><em>Complexity · ${esc(item.complexity)}</em></article>`).join("")}</div>
      </section>
      <section class="block">
        <div class="block-head"><h2>Key project enhancements</h2></div>
        <div class="change-list">${KEY_CHANGES.map((item) => `<article><div>${badge(item.type)}<h3>${esc(item.title)}</h3></div><p>${esc(item.text)}</p></article>`).join("")}</div>
      </section>
    </section>`;
}

function viewScope() {
  const bands = [
    ["existing", "Existing functionality", "Already described in the approved scope.", SCOPE.existing],
    ["fresh", "New major requirements", "These change the shape of booking, pricing and access.", SCOPE.fresh],
    ["enhance", "Enhancements", "The capability is in scope. The client’s version is more specific.", SCOPE.enhance],
    ["bugs", "Bug fixes", "Corrections inside behaviour the product already has.", SCOPE.bugs]
  ];
  return `
    <section class="page">
      ${pageHead("Project scope", "Four kinds of work, kept separate on purpose.", "Calling all 28 points new development would misstate the original document. The clean change request is the split below.")}
      ${bands.map(([id, title, lede, items]) => `
        <section class="scope-band scope-${id}">
          <header><h2>${title}</h2><p>${lede}</p></header>
          <ul>${items.map((item) => `<li>${esc(item)}</li>`).join("")}</ul>
        </section>`).join("")}
    </section>`;
}

function viewJourney() {
  const step = JOURNEY[state.journey];
  return `
    <section class="page">
      ${pageHead("User journey", "Fifteen steps, from sign-in to the booking record.", "Select a step. The note and the preview stay with that moment in the journey.")}
      <div class="journey">
        <ol class="journey-rail">
          ${JOURNEY.map((item, index) => `<li><button type="button" data-action="journey" data-index="${index}" aria-pressed="${index === state.journey}"><span>${pad(index + 1)}</span><strong>${esc(item.title)}</strong></button></li>`).join("")}
        </ol>
        <article class="journey-detail">
          <p class="kicker">Step ${state.journey + 1} of ${JOURNEY.length}</p>
          <h2>${esc(step.title)}</h2>
          <p>${esc(step.text)}</p>
          <div class="preview">${journeyPreview(step.id)}</div>
          <div class="hero-actions">
            <button type="button" class="btn secondary" data-action="journey" data-index="${Math.max(0, state.journey - 1)}">Previous</button>
            <button type="button" class="btn" data-action="journey" data-index="${Math.min(JOURNEY.length - 1, state.journey + 1)}">Next step</button>
          </div>
        </article>
      </div>
    </section>`;
}

function journeyPreview(id) {
  const previews = {
    login: renderAuthPanel(),
    location: `<div class="mini-venues">${VENUES.map((venue) => `<article><strong>${esc(venue.name)}</strong><span>${esc(venue.hours)}</span></article>`).join("")}</div>`,
    sport: `<div class="sport-picks">${sportsAt("thudiyalur").map((sport) => `<span>${sportIcon(sport.id)}${esc(sport.name)}</span>`).join("")}</div>`,
    court: `<div class="court-picks">${courtsFor("thudiyalur", "badminton").map((court) => `<span><strong>${esc(court.name)}</strong><small>Own calendar</small></span>`).join("")}</div>`,
    date: `<div class="mini-cal">${renderCalendar()}</div>`,
    slots: `<div class="mini-slots"><span class="slot slot-available"><b>7:00 PM</b><small>Available · ₹1,000</small></span><span class="slot slot-booked"><b>6:00 PM</b><small>Booked · half court held</small></span><span class="slot slot-past"><b>9:00 AM</b><small>Past · already started</small></span></div>`,
    duration: `<div><p class="quiet">Duration</p>${renderDuration()}<p class="quiet">The board rebuilds around the selected length.</p></div>`,
    mode: renderModes(),
    people: renderHeadcount(),
    discount: `<div class="quote"><div class="sum-line"><span>₹350 × 5</span><strong>₹1,750</strong></div><div class="sum-line"><span>Group rate for 5 or more</span><strong>−₹250</strong></div><div class="sum-line total"><span>Final amount</span><strong>₹1,500</strong></div></div>`,
    price: renderSummaryBody(),
    pay: `<div class="pay-states">${["Pending", "Processing", "Success", "Failed"].map((item) => `<span class="pill pill-${statusClass(item === "Success" ? "Paid" : item === "Failed" ? "Failed" : item)}">${item}</span>`).join("")}</div>`,
    confirm: `<div class="success-mini"><strong>Payment successful</strong><span>RIAM-10601 · Thudiyalur · Basketball · Court 1</span></div>`,
    whatsapp: whatsAppCard(BOOKINGS[1]),
    history: `<ul class="history-mini">${allBookings().filter((row) => row.customer === "Arun Kumar").map((row) => `<li><strong>${esc(row.id)}</strong><span>${esc(sportById(row.sportId).name)} · ${esc(fmtDay(row.date))}</span></li>`).join("")}</ul>`
  };
  return previews[id] || "";
}

function viewCustomer() {
  return `
    <section class="page">
      ${pageHead("Customer app", "Who it is for, and how a customer gets in.", "The customer books. The venue manager configures. Accounts follows the payment. Turf Town and the booking API stay connected to availability.")}
      <div class="audience">${AUDIENCES.map((item) => `<article><h2>${esc(item.title)}</h2><p>${esc(item.text)}</p></article>`).join("")}</div>
      <div class="split">
        <div>
          <h2>Sign in</h2>
          <p class="lede-sm">Google remains. Phone and OTP are added because a WhatsApp reminder needs a real mobile number.</p>
          ${renderAuthPanel()}
        </div>
        <div>
          <h2>Get directions</h2>
          <p class="lede-sm">The button opens the Maps URL saved on the venue. It does not build a fresh search from the street address.</p>
          ${VENUES.map((venue) => `
            <article class="venue-link">
              <header><strong>${esc(venue.name)}</strong><span>${esc(venue.address)}</span></header>
              ${field("Google Maps URL", `<input id="maps-${venue.id}" data-bind="maps.${venue.id}" value="${esc(state.maps[venue.id])}" />`, state.mapsError[venue.id] || "")}
              <div class="hero-actions">
                <button type="button" class="btn secondary" data-action="save-map" data-venue="${venue.id}">Save</button>
                <button type="button" class="btn" data-action="directions" data-venue="${venue.id}">${icon("map")} Get Directions</button>
              </div>
            </article>`).join("")}
        </div>
      </div>
    </section>`;
}

function viewBooking() {
  const sport = sportById(state.draft.sportId);
  const court = courtById(state.draft.courtId);
  return `
    <section class="page">
      ${pageHead("Booking flow", `${esc(venueById(state.draft.venueId).name)} · ${esc(sport.name)} · ${esc(court?.name || "Court")}`, "Choose a date, a duration and a slot. Blocked times stay on the board with a reason, so a customer can tell a full court from a broken screen.")}
      <div class="selector-row">
        ${draftSelects()}
      </div>
      <div class="studio">
        <aside class="studio-side">
          <h2>Date</h2>
          ${renderCalendar()}
          <h2>Duration</h2>
          ${renderDuration()}
          ${state.draft.venueId === "thudiyalur" ? `<button type="button" class="chip" data-action="toggle-overnight" aria-pressed="${state.showOvernight}">${state.showOvernight ? "Showing overnight hours" : "Include 12 AM – 6 AM"}</button><p class="quiet">Thudiyalur is open 24 hours. The board opens on 6:00 AM to midnight.</p>` : ""}
        </aside>
        <div>
          <div class="block-head"><h2>Time slots</h2>${slotLegend()}</div>
          ${renderSlotBoard()}
          <div class="studio-lower">
            <div><h2>Booking mode</h2>${renderModes()}</div>
            <div><h2>Headcount</h2>${renderHeadcount()}</div>
          </div>
        </div>
      </div>
      <section class="summary-panel">
        <div>
          <h2>Booking summary</h2>
          ${renderSummaryBody()}
        </div>
        <div class="summary-cta">
          <button type="button" class="btn" data-action="go-pay">Proceed to payment</button>
          <p class="quiet">Payment uses the existing Razorpay flow. Production keys are still a client decision.</p>
        </div>
      </section>
    </section>`;
}

function draftSelects() {
  const sports = sportsAt(state.draft.venueId);
  const courts = courtsFor(state.draft.venueId, state.draft.sportId);
  return `
    <label>Venue<select data-draft="venueId">${VENUES.map((venue) => `<option value="${venue.id}"${venue.id === state.draft.venueId ? " selected" : ""}>${esc(venue.name)}</option>`).join("")}</select></label>
    <label>Sport<select data-draft="sportId">${sports.map((sport) => `<option value="${sport.id}"${sport.id === state.draft.sportId ? " selected" : ""}>${esc(sport.name)}</option>`).join("")}</select></label>
    <label>Court<select data-draft="courtId">${courts.map((court) => `<option value="${court.id}"${court.id === state.draft.courtId ? " selected" : ""}>${esc(court.name)}</option>`).join("")}</select></label>`;
}

function viewVenues() {
  const tabs = [["hierarchy", "Hierarchy"], ["facilities", "Facilities"], ["modes", "Booking modes"], ["migration", "Migration"]];
  const panels = { hierarchy: viewHierarchy(), facilities: viewFacilities(), modes: viewModes(), migration: viewMigration() };
  return `
    <section class="page">
      ${pageHead("Venue and court management", "Sport, then venue, then the physical court, then the way it can be booked.", "Thudiyalur and Saibaba do not offer the same sports. Each court on this page can be selected on its own.")}
      <div class="tabs">${tabs.map(([id, label]) => `<button type="button" data-action="venue-tab" data-tab="${id}" aria-pressed="${state.venueTab === id}">${label}</button>`).join("")}</div>
      ${panels[state.venueTab]}
    </section>`;
}

function viewHierarchy() {
  return `
    <div class="tree-layout">
      <div class="sport-rail">
        ${SPORTS.map((sport) => `<button type="button" data-action="tree-sport" data-sport="${sport.id}" aria-pressed="${state.treeSport === sport.id}">${sportIcon(sport.id)}<span>${esc(sport.name)}</span></button>`).join("")}
      </div>
      <div class="tree-detail">${hierarchyDetail(state.treeSport)}</div>
    </div>
    <ol class="chain">
      ${["Sport", "Venue", "Court / resource", "Booking mode", "Price", "Time slot"].map((item) => `<li>${item}</li>`).join("")}
    </ol>`;
}

function hierarchyDetail(sportId) {
  const sport = sportById(sportId);
  const venues = VENUES.filter((venue) => sportsAt(venue.id, true).some((item) => item.id === sportId));
  return `
    <header><h2>${sportIcon(sportId)} ${esc(sport.name)}</h2><p>${(MODES[sportId] || []).map((mode) => esc(mode.priceLabel)).join(" · ")}</p></header>
    ${venues.map((venue) => `
      <section>
        <h3>${esc(venue.name)}</h3>
        <div class="court-picks">
          ${courtsFor(venue.id, sportId, { includeInactive: true, includeLegacy: true }).map((court) => `
            <button type="button" data-action="focus-court" data-court="${court.id}" aria-pressed="${state.courtFocus === court.id}">
              <strong>${esc(court.name)}</strong>
              <small>${isInactive(court) ? "Deactivated · retained" : "Own calendar"}</small>
            </button>`).join("")}
        </div>
      </section>`).join("")}
    ${state.courtFocus && courtById(state.courtFocus)?.sportId === sportId ? courtFocusCard(state.courtFocus) : ""}`;
}

function courtFocusCard(courtId) {
  const court = courtById(courtId);
  const upcoming = allBookings().filter((booking) => booking.courtId === courtId).slice(0, 3);
  return `
    <article class="focus-card">
      <header><strong>${esc(court.name)}</strong>${pill(isInactive(court) ? "Deactivated" : "Active")}</header>
      <div class="focus-grid">
        <section><h3>Calendar</h3><p>Availability is calculated for this resource only.</p></section>
        <section><h3>Pricing</h3><p>${(MODES[court.sportId] || []).map((mode) => esc(mode.priceLabel)).join(" · ")}</p></section>
        <section><h3>Availability</h3><p>${isInactive(court) ? "Hidden from new bookings." : "Open times follow the venue hours and existing holds."}</p></section>
        <section><h3>Booking history</h3>${upcoming.length ? `<ul>${upcoming.map((booking) => `<li>${esc(booking.id)} · ${esc(fmtDay(booking.date))}</li>`).join("")}</ul>` : "<p>No scenario bookings on this court yet.</p>"}</section>
      </div>
    </article>`;
}

function viewFacilities() {
  return VENUES.map((venue) => `
    <article class="facility">
      <header>
        <div><h2>${esc(venue.name)}</h2><p>${esc(venue.blurb)}</p></div>
        <span>${esc(venue.hours)}</span>
      </header>
      ${sportsAt(venue.id).map((sport) => `
        <div class="facility-sport">
          <h3>${sportIcon(sport.id)} ${esc(sport.name)}</h3>
          <div class="court-picks">${courtsFor(venue.id, sport.id).map((court) => `<span><strong>${esc(court.name)}</strong><small>Status · Active</small><small>Separate calendar</small></span>`).join("")}</div>
        </div>`).join("")}
    </article>`).join("");
}

function viewModes() {
  const examples = [
    { sport: "basketball", venue: "thudiyalur", court: "td-bb-1" },
    { sport: "swimming", venue: "saibaba", court: "sb-sw-1" }
  ];
  return `
    <p class="lede-sm">The selected mode updates the price, the capacity and the summary together.</p>
    <div class="mode-labs">
      ${examples.map((example) => {
        const active = state.draft.sportId === example.sport;
        return `<article>
          <header><h2>${esc(sportById(example.sport).name)}</h2><button type="button" class="btn secondary" data-action="load-example" data-sport="${example.sport}" data-venue="${example.venue}" data-court="${example.court}">Use in summary</button></header>
          <div class="mode-grid">
            ${(MODES[example.sport] || []).map((mode) => `<button type="button" class="mode-card" data-action="example-mode" data-sport="${example.sport}" data-venue="${example.venue}" data-court="${example.court}" data-mode="${mode.id}" aria-pressed="${active && state.draft.modeId === mode.id}"><span>${esc(mode.name)}</span><strong>${esc(mode.priceLabel)}</strong><small>${esc(mode.capacity)}</small></button>`).join("")}
          </div>
        </article>`;
      }).join("")}
    </div>
    <aside class="summary-panel flat"><div><h2>Live summary</h2>${renderSummaryBody()}</div><div>${renderHeadcount()}</div></aside>`;
}

function viewMigration() {
  return `
    <div class="migrate">
      <article>
        <p class="kicker">Current workaround</p>
        <h2>A separate service for every court</h2>
        <ul>
          <li>Badminton Court 1 as its own service</li>
          <li>Badminton Court 2 as its own service</li>
          <li>The same pattern repeated so courts could be booked at all</li>
        </ul>
      </article>
      <div class="migrate-arrow" aria-hidden="true">${icon("arrow")}</div>
      <article>
        <p class="kicker">New structure</p>
        <h2>One sport, many real courts</h2>
        <ol class="chain vertical">
          <li>Sport</li><li>Venue</li><li>Court</li><li>Booking mode</li>
        </ol>
      </article>
    </div>
    <div class="inline-note">${icon("lock")}<p><strong>Existing bookings keep working.</strong> Deactivated legacy services are not deleted when a booking still points at them. RIAM-10220 stays attached to “Legacy service · Badminton Court 2”.</p></div>
    <div class="map-table">
      <div><span>Legacy service</span><strong>Badminton Court 2 service</strong></div>
      <div><span>New resource</span><strong>Badminton · Thudiyalur · Court 2</strong></div>
      <div><span>Historical booking</span><strong>RIAM-10220 · retained</strong></div>
      <div><span>Validation</span><strong>Counts, references and Turf Town sync checked after mapping</strong></div>
    </div>`;
}

function viewPricing() {
  return `
    <section class="page">
      ${pageHead("Pricing and booking rules", "The rate follows the venue, the clock, the mode and the people in the booking.", "Hourly pricing and location-wise pricing are already in the approved scope. The change is a real time band, a price that can differ by venue, and a total that changes with headcount.")}
      <div class="split">
        <article class="paper">
          <div class="block-head"><h2>Pickleball</h2><div class="seg">${VENUES.map((venue) => `<button type="button" class="chip" data-action="band-venue" data-venue="${venue.id}" aria-pressed="${state.pricingVenue === venue.id}">${esc(venue.name)}</button>`).join("")}</div></div>
          ${bandVisual("pickleball", state.pricingVenue)}
          <h2 class="spaced">Football · Thudiyalur</h2>
          ${bandVisual("football", "thudiyalur")}
        </article>
        <article class="paper">
          <h2>Headcount calculator</h2>
          <p class="quiet">Choose a per-person sport. Five swimmers at the group rate come to ₹1,500.</p>
          <div class="seg">
            <button type="button" class="chip" data-action="calc-sport" data-sport="swimming" aria-pressed="${state.draft.sportId === "swimming"}">Swimming ₹350</button>
            <button type="button" class="chip" data-action="calc-sport" data-sport="badminton" aria-pressed="${state.draft.sportId === "badminton"}">Badminton ₹150</button>
          </div>
          ${renderHeadcount()}
          ${renderQuote(currentQuote())}
        </article>
      </div>
      <section class="block">
        <div class="block-head"><h2>Where a price is allowed to live</h2></div>
        <div class="scope-pills">${["Sport", "Venue", "Court", "Time range", "Booking mode"].map((item) => `<span>${item}</span>`).join("")}</div>
      </section>
    </section>`;
}

function bandVisual(sportId, venueId) {
  const bands = (BANDS[sportId] || {})[venueId];
  if (!bands) return `<p class="quiet">This sport is not offered at the selected venue.</p>`;
  const total = bands.reduce((sum, band) => sum + (band.end - band.start), 0);
  return `
    <div class="price-bar" aria-hidden="true">${bands.map((band) => `<span style="flex:${band.end - band.start} ${band.end - band.start} 0" class="${band.start >= 18 * 60 ? "is-night" : "is-day"}">${inr(band.rate)}</span>`).join("")}</div>
    <ul class="band-key">${bands.map((band) => `<li><strong>${inr(band.rate)} / hour</strong><span>${esc(band.label)}${band.sample ? ` ${sampleTag()}` : ""}</span></li>`).join("")}</ul>
    ${bands.some((band) => band.sample) ? `<p class="quiet">Saibaba pickleball figures are samples, so the review can show a different venue rate. Thudiyalur uses the client’s ₹600 and ₹800 bands.</p>` : ""}
    <span class="sr-only">${total}</span>`;
}

function viewAvailability() {
  return `
    <section class="page">
      ${pageHead("Availability and operating hours", "A closed day and a class block are visible, and neither one can be booked.", "Thudiyalur is open 24 hours. Saibaba swimming follows the weekly pattern below. Booked and past slots use their own colour, label and reason.")}
      <div class="hours-grid">
        <article class="paper">
          <h2>Thudiyalur</h2>
          <p class="hours-state">Open 24 / 7</p>
          <p>Court calendars still apply. A booked badminton court does not close the court beside it.</p>
        </article>
        <article class="paper">
          <header class="block-head"><h2>Saibaba · swimming</h2><button type="button" class="chip" data-action="toggle-wednesday" aria-pressed="${state.swim.closedDays.includes(3)}">${state.swim.closedDays.includes(3) ? "Wednesday closed" : "Wednesday open in this preview"}</button></header>
          <h3>Wednesday</h3>
          ${state.swim.closedDays.includes(3) ? renderSchedule("closed") : renderSchedule("standard")}
          <h3>Monday, Tuesday, Thursday, Friday, Saturday</h3>
          ${renderSchedule("standard")}
          <h3>Sunday</h3>
          ${renderSchedule("sunday")}
        </article>
      </div>
      <section class="block">
        <div class="block-head"><h2>Try the board</h2><p>Switch to Saibaba swimming and choose Wednesday 7 Oct, or Sunday 4 Oct, to see closure and class periods.</p></div>
        <div class="selector-row">${draftSelects()}</div>
        ${slotLegend()}
        <div class="studio single">${renderCalendar()}<div>${renderDuration()}${renderSlotBoard()}</div></div>
      </section>
    </section>`;
}

function viewPayments() {
  const stages = ["Pending", "Processing", "Success", "Failed"];
  return `
    <section class="page">
      ${pageHead("Payments", "Razorpay is already the payment module. Live activation is the remaining step.", "Success, failure and callbacks are part of the approved payment scope. The connector the client is using is still on a test configuration.")}
      <div class="split">
        <article class="paper">
          <h2>Payment states</h2>
          <div class="seg">${stages.map((stage) => `<button type="button" class="chip" data-action="pay-preview" data-stage="${stage.toLowerCase()}" aria-pressed="${state.payPreview === stage.toLowerCase()}">${stage}</button>`).join("")}</div>
          ${paymentPreview(state.payPreview)}
        </article>
        <article class="paper">
          <div class="block-head"><h2>Production configuration</h2>${badge("enhance")}</div>
          <p>Moving from test to live is a credential and deployment change, followed by a real payment check.</p>
          <ul class="checklist">
            <li>Live Key ID and Key Secret from the client’s Razorpay account</li>
            <li>Production webhook secret and callback URL</li>
            <li>A validated success and a validated failure</li>
            <li>Existing booking and payment records left intact</li>
          </ul>
          <button type="button" class="btn secondary" data-action="toggle-razorpay">${state.razorpayMode === "test" ? "Preview the live badge" : "Return to test badge"}</button>
          <p class="quiet">${state.razorpayMode === "test" ? "This review is showing test mode." : "Live badge is a preview only. It does not activate the client’s Razorpay account."}</p>
        </article>
      </div>
      <section class="block">
        <div class="block-head"><h2>Transaction fields for the booking API</h2>${badge("new")}</div>
        <p class="lede-sm">The API can already read booked and open slots. Payment fields should be added only after this list is confirmed.</p>
        <div class="check-grid">${API_FIELDS.map(([id, label]) => `<label><input type="checkbox" data-api="${id}" ${state.apiFields[id] ? "checked" : ""} /> ${esc(label)}</label>`).join("")}</div>
      </section>
    </section>`;
}

function paymentPreview(stage) {
  if (stage === "processing") return `<div class="pay-card"><div class="spinner"></div><strong>Processing payment</strong><p>Waiting for Razorpay to confirm.</p></div>`;
  if (stage === "failed") return `<div class="pay-card failed"><strong>Payment failed</strong><p>The court has not been confirmed. The customer can try again. Booking RIAM-10102 in the register shows this state.</p></div>`;
  if (stage === "pending") return `<div class="pay-card"><strong>Payment pending</strong><p>The booking is held only while the payment is still in progress.</p></div>`;
  return `
    <div class="pay-card success">
      <strong>Payment successful</strong>
      <dl class="facts">
        <div><dt>Booking ID</dt><dd>RIAM-10601</dd></div>
        <div><dt>Venue</dt><dd>Thudiyalur</dd></div>
        <div><dt>Sport</dt><dd>Basketball</dd></div>
        <div><dt>Court</dt><dd>Court 1</dd></div>
        <div><dt>Date</dt><dd>Sun, 4 Oct 2026</dd></div>
        <div><dt>Time</dt><dd>7:00 PM – 8:00 PM</dd></div>
        <div><dt>Amount</dt><dd>₹1,000</dd></div>
      </dl>
      <div class="hero-actions"><span class="btn secondary">View booking</span><span class="btn secondary">${icon("download")} Download confirmation</span></div>
    </div>`;
}

function viewNotifications() {
  const kinds = [
    ["Booking created", "The reservation exists and is waiting for payment confirmation."],
    ["Payment successful", "Razorpay has confirmed the amount."],
    ["Booking confirmed", "The court, time and booking ID are final."],
    ["Reminder", "A reminder goes out before the slot, using the verified mobile number."],
    ["Cancellation", "The court is released and the message records the cancellation."]
  ];
  return `
    <section class="page">
      ${pageHead("Notifications", "WhatsApp is already in scope. Messages now carry the court and the directions link.", "The channel stays. The content follows the new booking: court, mode, time, amount and the stored Maps URL.")}
      <div class="note-grid">
        <ul class="note-list">${kinds.map(([title, text]) => `<li><strong>${title}</strong><span>${text}</span></li>`).join("")}</ul>
        ${whatsAppCard({ id: "RIAM-10490", venueId: "thudiyalur", sportId: "basketball", courtId: "td-bb-1", date: "2026-10-04", start: "16:00", duration: 60, amount: 1000 })}
      </div>
    </section>`;
}

function viewAdmin() {
  const metrics = scenarioMetrics();
  const cards = [
    ["Total bookings", metrics.total],
    ["Today’s bookings", metrics.today],
    ["Scenario revenue", inr(metrics.revenue)],
    ["Active venues", metrics.venues],
    ["Active courts", metrics.courts],
    ["Pending payments", metrics.pending]
  ];
  return `
    <section class="page">
      ${pageHead("Admin panel", "The operating tools behind venues, courts, prices and payments.", "Figures in this review come from the scenario register, plus the prices the client has already stated.")}
      <div class="metric-strip">${cards.map(([label, value]) => `<article><span>${label}</span><strong>${value}</strong></article>`).join("")}</div>
      <div class="module-grid">${ADMIN_MODULES.map(([title, text]) => `<article><h2>${title}</h2><p>${text}</p></article>`).join("")}</div>
      <section class="block" id="admin-courts"><div class="block-head"><h2>Courts</h2><p>Create and assign in the full prototype. Deactivate here, and see that delete is refused for a legacy record.</p></div>${renderCourtAdmin()}</section>
      <section class="block"><div class="block-head"><h2>Pricing</h2></div>${renderPricingAdmin()}</section>
      <section class="block"><div class="block-head"><h2>Bookings</h2></div>${renderBookingFilters()}${renderBookingTable()}</section>
      <section class="block"><div class="block-head"><h2>Transactions</h2><p>The same payment facts the booking API should be able to return.</p></div>${renderTxnTable()}</section>
    </section>`;
}

function viewCompare() {
  const filters = [["all", "All"], ["new", "New"], ["enhance", "Enhancement"], ["bug", "Bug fix"], ["ui", "UI"], ["existing", "Existing"]];
  const rows = TRACKER.filter((row) => state.trackerFilter === "all" || row.type === state.trackerFilter);
  return `
    <section class="page">
      ${pageHead("Existing, enhancement, or new", "One register for the whole change request.", "Use the filter to walk the client through only the new work, only the fixes, or the full comparison.")}
      <div class="seg">${filters.map(([id, label]) => `<button type="button" class="chip" data-action="tracker" data-filter="${id}" aria-pressed="${state.trackerFilter === id}">${label}</button>`).join("")}</div>
      <div class="table-wrap">
        <table class="table tracker">
          <thead><tr><th>Item</th><th>Current behaviour</th><th>Required behaviour</th><th>Type</th><th>Priority</th><th>Status</th></tr></thead>
          <tbody>
            ${rows.map((row) => `<tr><td><strong>${esc(row.item)}</strong></td><td>${esc(row.current)}</td><td>${esc(row.required)}</td><td>${badge(row.type === "ui" ? "ui" : row.type)}</td><td>${esc(row.priority)}</td><td>${esc(row.status)}</td></tr>`).join("")}
          </tbody>
        </table>
      </div>
      <div class="split bug-labs">
        <article class="paper">
          <h2>Reported assignment bug</h2>
          <p>Cricket was unchecked for Saibaba. The screen said it was saved, then Cricket became selected again and stayed bookable.</p>
          <label class="check-line"><input type="checkbox" data-action="bug-toggle" ${state.bugChecked ? "checked" : ""} /> Cricket at Saibaba Colony</label>
          <p class="field-error">${state.bugNote || "Uncheck it. The current behaviour puts the tick back."}</p>
        </article>
        <article class="paper">
          <h2>Required behaviour</h2>
          <p>Removing the venue removes Cricket from Saibaba discovery and from new bookings.</p>
          <label class="check-line"><input type="checkbox" data-action="fix-toggle" ${state.fixChecked ? "checked" : ""} /> Cricket at Saibaba Colony</label>
          <p class="ok-text">${state.fixChecked ? "Assigned. Saibaba would show Cricket." : "Unassigned. Saibaba shows pickleball and swimming only."}</p>
        </article>
      </div>
      <article class="paper icon-fix">
        <h2>Sport icons</h2>
        <div class="icon-cols">
          <div><h3>Current mapping</h3>${iconPair("badminton", "football")}${iconPair("cricket", "basketball")}${iconPair("football", "cricket")}</div>
          <div><h3>Required mapping</h3>${SPORTS.slice(0, 3).map((sport) => `<p>${sportIcon(sport.id)} ${esc(sport.name)}</p>`).join("")}</div>
        </div>
      </article>
    </section>`;
}

function iconPair(sportId, wrongId) {
  return `<p><span class="struck">${sportIcon(wrongId)} ${esc(sportById(sportId).name)}</span></p>`;
}

function viewRules() {
  return `
    <section class="page">
      ${pageHead("Business rules", "Twelve rules the booking engine has to keep.", "These are the rules behind the screens. If a later decision changes a price or a closure, the rule stays and the configured value changes.")}
      <ol class="rules">${RULES.map((rule) => `<li><span>${rule.n}</span><div><h2>${esc(rule.title)}</h2><p>${esc(rule.text)}</p></div></li>`).join("")}</ol>
    </section>`;
}

function viewTechnical() {
  const integrations = ["Razorpay", "WhatsApp", "Google Maps", "Turf Town API"];
  return `
    <section class="page">
      ${pageHead("Technical overview", "A single booking application, with the services already around it.", "Court-level availability has to be checked against Turf Town synchronisation, because that sync is already part of the platform.")}
      <div class="arch">
        <div class="arch-node">Customer web app</div>
        <div class="arch-line"></div>
        <div class="arch-node">Application and API</div>
        <div class="arch-line"></div>
        <div class="arch-node">Database · venues, sports, courts, modes, bookings, payments</div>
        <div class="arch-line"></div>
        <div class="arch-row">${integrations.map((item) => `<div class="arch-node small">${item}</div>`).join("")}</div>
      </div>
      <div class="three tech-notes">
        <article><h2>What stays</h2><p>Google login, Razorpay callbacks, booking history, admin roles and Turf Town synchronisation.</p></article>
        <article><h2>What changes shape</h2><p>Availability, price and capacity move from a service record to a court and a booking mode.</p></article>
        <article><h2>What gets added</h2><p>OTP, operating rules, discount rules, a stored Maps URL and transaction fields on the API.</p></article>
      </div>
    </section>`;
}

function viewTimeline() {
  return `
    <section class="page">
      ${pageHead("Timeline and effort", "Effort estimation to be finalized after technical validation.", "No day count is proposed here. Each area records complexity, dependencies, migration impact and testing impact so an estimate can be grounded.")}
      <blockquote class="pull">“Rough timelines on 1, 2 and 3 would help, those are the ones actually serious.”<cite>Client note</cite></blockquote>
      <div class="timeline">${TIMELINE.map((item) => `
        <article>
          <header><span>${item.n}</span><h2>${esc(item.title)}</h2><em>${esc(item.complexity)}</em></header>
          <dl>
            <div><dt>Dependencies</dt><dd>${esc(item.dependencies)}</dd></div>
            <div><dt>Migration impact</dt><dd>${esc(item.migration)}</dd></div>
            <div><dt>Testing impact</dt><dd>${esc(item.testing)}</dd></div>
          </dl>
          <p>${esc(item.note)}</p>
        </article>`).join("")}
      </div>
    </section>`;
}

function viewDecisions() {
  const labels = { confirmed: "Confirmed", pending: "Pending", clarify: "Needs clarification" };
  return `
    <section class="page">
      ${pageHead("Client decisions required", "These answers close the estimate.", "Choices made in this room are saved in the browser for the rest of the review.")}
      <div class="decisions">${DECISIONS.map((item) => `
        <article>
          <header><h2>${esc(item.title)}</h2>${pill(labels[state.decisions[item.id]] || "Pending")}</header>
          <p>${esc(item.detail)}</p>
          <div class="seg">
            ${Object.entries(labels).map(([id, label]) => `<button type="button" class="chip" data-action="decision" data-id="${item.id}" data-status="${id}" aria-pressed="${state.decisions[item.id] === id}">${label}</button>`).join("")}
          </div>
        </article>`).join("")}
      </div>
    </section>`;
}

const PAGES = {
  overview: viewOverview,
  scope: viewScope,
  journey: viewJourney,
  customer: viewCustomer,
  booking: viewBooking,
  venues: viewVenues,
  pricing: viewPricing,
  availability: viewAvailability,
  payments: viewPayments,
  notifications: viewNotifications,
  admin: viewAdmin,
  compare: viewCompare,
  rules: viewRules,
  technical: viewTechnical,
  timeline: viewTimeline,
  decisions: viewDecisions
};
