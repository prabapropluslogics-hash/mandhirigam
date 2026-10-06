function presentationHtml() {
  const slide = SLIDES[state.slide];
  return `
    <div class="pres" role="dialog" aria-modal="true" aria-label="Presentation mode">
      <header class="pres-bar">
        <strong>RIAM Sports</strong>
        <span>${esc(slide.kicker)} · ${state.slide + 1} / ${SLIDES.length}</span>
        <button type="button" class="btn secondary" data-action="close-pres">Exit</button>
      </header>
      <div class="pres-stage">${slideBody(slide.id)}</div>
      <footer class="pres-nav">
        <button type="button" class="btn secondary" data-action="slide" data-dir="-1" ${state.slide === 0 ? "disabled" : ""}>Previous</button>
        <div class="pres-dots">${SLIDES.map((item, index) => `<button type="button" data-action="slide-to" data-index="${index}" aria-label="${esc(item.kicker)}" aria-pressed="${index === state.slide}"></button>`).join("")}</div>
        <button type="button" class="btn" data-action="slide" data-dir="1" ${state.slide === SLIDES.length - 1 ? "disabled" : ""}>Next</button>
      </footer>
    </div>`;
}

function slideBody(id) {
  const bodies = {
    problem: `<p class="kicker">Problem</p><h2>The booking model stops at the sport.</h2><p class="pres-lede">Customers can find a venue and a sport. They still cannot book Court 2, choose half court or full court, or see that Wednesday swimming is closed.</p><ol class="flow">${["Sport", "Court", "Mode", "Time", "Price"].map((step) => `<li><span></span>${step}</li>`).join("")}</ol>`,
    current: `<p class="kicker">Current system</p><h2>The core platform is already in the approved scope.</h2><ul class="pres-chips">${SCOPE.existing.slice(0, 10).map((item) => `<li>${esc(item)}</li>`).join("")}</ul><p>Discovery, hourly slots, Razorpay, Google login, admin, roles and Turf Town sync stay. They are not new modules.</p>`,
    changes: `<p class="kicker">Required changes</p><h2>Separate the work before anyone calls it all new.</h2><div class="pres-counts"><article><b>${SCOPE.fresh.length}</b><span>New requirements</span></article><article><b>${SCOPE.enhance.length + 1}</b><span>Enhancements and UI</span></article><article><b>${SCOPE.bugs.length}</b><span>Bug fixes</span></article><article><b>${SCOPE.existing.length}</b><span>Already covered</span></article></div>`,
    architecture: `<p class="kicker">New booking architecture</p><h2>Basketball Court 1 can be half court or full court.</h2><div class="pres-arch"><div><h3>Badminton</h3><p>Courts 1–4 · ₹150 / person</p></div><div><h3>Basketball</h3><p>Half court ₹600 · Full court ₹1,000</p></div><div><h3>Swimming</h3><p>₹350 / person · Private pool ₹3,500</p></div></div>`,
    flow: `<p class="kicker">User flow</p><h2>Every blocked slot gives a reason.</h2><div class="mini-slots pres-slots"><span class="slot slot-available"><b>Available</b><small>Open for booking</small></span><span class="slot slot-booked"><b>Booked</b><small>Reserved by another customer</small></span><span class="slot slot-past"><b>Past</b><small>This time has passed</small></span><span class="slot slot-class"><b>Class</b><small>5:00–8:00 PM is not for rental</small></span><span class="slot slot-closed"><b>Closed</b><small>Wednesday · pool closed</small></span></div>`,
    pricing: `<p class="kicker">Pricing</p><h2>Five swimmers are not priced as one.</h2><div class="split pres-split"><div>${bandVisual("pickleball", "thudiyalur")}<p class="quiet">Pickleball at Thudiyalur, using the client’s bands.</p></div><div class="quote"><div class="sum-line"><span>₹350 × 5</span><strong>₹1,750</strong></div><div class="sum-line"><span>Group rate for 5 or more</span><strong>−₹250</strong></div><div class="sum-line total"><span>Final amount</span><strong>₹1,500</strong></div></div></div>`,
    availability: `<p class="kicker">Availability</p><h2>Saibaba swimming has hours, a closure and a class.</h2><div class="hours-grid"><article><h3>Wednesday</h3>${renderSchedule("closed")}</article><article><h3>Monday to Saturday, except Wednesday</h3>${renderSchedule("standard")}</article><article><h3>Sunday</h3>${renderSchedule("sunday")}</article></div>`,
    payment: `<p class="kicker">Payment</p><h2>Keep Razorpay. Activate the live account.</h2><div class="pres-counts"><article><b>Existing</b><span>Checkout, success, failure, callbacks</span></article><article><b>Change</b><span>Test configuration to production</span></article><article><b>New</b><span>Transaction fields on the booking API</span></article></div>`,
    admin: `<p class="kicker">Admin</p><h2>Managers need courts, rates, hours and payments in one place.</h2><ul class="pres-chips">${ADMIN_MODULES.slice(0, 12).map(([title]) => `<li>${esc(title)}</li>`).join("")}</ul><p>Deactivating a court keeps the record when a past booking still points at it.</p>`,
    migration: `<p class="kicker">Migration</p><h2>The workaround becomes a real court list.</h2><div class="migrate"><article><h3>Today</h3><p>Each court was entered as its own service.</p></article><div class="migrate-arrow">${icon("arrow")}</div><article><h3>After</h3><p>Sport, venue, court, booking mode. RIAM-10220 still resolves.</p></article></div>`,
    technical: `<p class="kicker">Technical architecture</p><h2>Customer app, API, database, then the services around them.</h2><div class="arch"><div class="arch-node">Customer web app</div><div class="arch-line"></div><div class="arch-node">Application and API</div><div class="arch-line"></div><div class="arch-node">Database</div><div class="arch-line"></div><div class="arch-row"><div class="arch-node small">Razorpay</div><div class="arch-node small">WhatsApp</div><div class="arch-node small">Google Maps</div><div class="arch-node small">Turf Town</div></div></div>`,
    timeline: `<p class="kicker">Timeline</p><h2>Effort estimation to be finalized after technical validation.</h2><div class="three">${TIMELINE.map((item) => `<article><span class="num">${item.n}</span><h3>${esc(item.title)}</h3><em>${esc(item.complexity)} complexity</em></article>`).join("")}</div>`,
    final: `<p class="kicker">Final scope</p><h2>The estimate waits on a short list of decisions.</h2><ul class="pres-chips">${DECISIONS.slice(0, 8).map((item) => `<li>${esc(item.title)}</li>`).join("")}</ul><button type="button" class="btn" data-action="exit-to" data-id="decisions">Open the decision list</button>`
  };
  return `<article class="slide">${bodies[id] || ""}</article>`;
}
