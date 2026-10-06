const ADMIN_JUMP = {
  Venues: "admin-venues",
  Sports: "admin-courts",
  Courts: "admin-courts",
  "Booking modes": "admin-pricing",
  Pricing: "admin-pricing",
  Availability: "admin-availability",
  "Operating hours": "admin-availability",
  Closures: "admin-availability",
  Classes: "admin-availability",
  Bookings: "admin-bookings",
  Customers: "admin-bookings",
  Payments: "admin-transactions",
  Discounts: "admin-pricing",
  Notifications: "admin-home",
  Reports: "admin-reports",
  "API / integrations": "admin-transactions",
  Settings: "admin-venues"
};

function mount() {
  const groups = [];
  NAV.forEach((item) => {
    const last = groups[groups.length - 1];
    if (!last || last.label !== item.group) groups.push({ label: item.group, items: [item] });
    else last.items.push(item);
  });
  document.getElementById("app").innerHTML = `
    <div class="shell" id="shell">
      <aside class="sidebar">
        <div class="brand"><span class="mark">R</span><span><strong>RIAM Sports</strong><em>Client review</em></span></div>
        <nav aria-label="Review sections">
          ${groups.map((group) => `<p class="nav-label">${group.label}</p>${group.items.map((item) => `<button type="button" data-nav="${item.id}" data-action="nav" data-id="${item.id}">${icon(item.icon)}<span>${item.label}</span></button>`).join("")}`).join("")}
        </nav>
      </aside>
      <div class="scrim" data-action="close-nav"></div>
      <main class="main" id="main">
        <header class="topbar">
          <button type="button" class="icon-btn" data-action="open-nav" aria-label="Open navigation">${icon("menu")}</button>
          <h1 id="page-title"></h1>
          <button type="button" class="btn secondary present-btn" data-action="present">${icon("play")} Presentation mode</button>
        </header>
        <div id="outlet" class="outlet"></div>
        <footer class="foot">Prepared for the RIAM Sports client review · October 2026. Named bookings are scenario records. Client-stated prices are shown as given. Other figures are marked Sample.</footer>
      </main>
    </div>
    <div id="modal-root"></div>
    <div id="toast-root"></div>
    <div id="pres-root"></div>`;
  state.mounted = true;
}

function updateChrome() {
  document.querySelectorAll("[data-nav]").forEach((button) => {
    const on = button.dataset.nav === state.route;
    button.classList.toggle("active", on);
    if (on) button.setAttribute("aria-current", "page");
    else button.removeAttribute("aria-current");
  });
  document.getElementById("shell").classList.toggle("nav-open", state.navOpen);
  const item = NAV.find((entry) => entry.id === state.route);
  const title = item ? item.label : "Overview";
  document.getElementById("page-title").textContent = title;
  document.title = `RIAM Sports — ${title}`;
}

function render(opts = {}) {
  if (!state.mounted) mount();
  const main = document.getElementById("main");
  const y = main ? main.scrollTop : 0;
  const active = document.activeElement;
  const focusId = active && active.id;
  const caret = active && typeof active.selectionStart === "number" ? active.selectionStart : null;
  updateChrome();
  let html = "";
  try {
    html = (PAGES[state.route] || PAGES.overview)();
  } catch (error) {
    console.error(error);
    html = `<section class="page"><div class="empty"><strong>This section could not be drawn.</strong><p>${esc(error.message)}</p></div></section>`;
  }
  document.getElementById("outlet").innerHTML = html;
  document.getElementById("modal-root").innerHTML = state.modal ? modalHtml() : "";
  document.getElementById("toast-root").innerHTML = state.toast ? `<div class="toast" role="status">${esc(state.toast)}</div>` : "";
  document.getElementById("pres-root").innerHTML = state.presentation ? presentationHtml() : "";
  if (main) main.scrollTop = opts.keepScroll ? y : 0;
  if (focusId) {
    const field = document.getElementById(focusId);
    if (field) {
      field.focus();
      if (caret != null && field.setSelectionRange) {
        try { field.setSelectionRange(caret, caret); } catch (error) { /* Some inputs reject a caret. */ }
      }
    }
  }
}

function modalHtml() {
  const modal = state.modal;
  return `<div class="modal-back" data-action="close-modal"><div class="modal" data-action="stop" role="dialog" aria-modal="true" aria-labelledby="modal-title"><h2 id="modal-title">${esc(modal.title)}</h2><p>${esc(modal.body)}</p><div class="hero-actions"><button type="button" class="btn secondary" data-action="close-modal">Cancel</button><button type="button" class="btn${modal.danger ? " danger" : ""}" data-action="modal-yes">${esc(modal.confirm)}</button></div></div></div>`;
}

function toast(message) {
  state.toast = message;
  state.toastToken = (state.toastToken || 0) + 1;
  const token = state.toastToken;
  render({ keepScroll: true });
  setTimeout(() => {
    if (state.toastToken === token) {
      state.toast = "";
      render({ keepScroll: true });
    }
  }, 2800);
}

function readHash() {
  const raw = (location.hash || "#overview").replace(/^#/, "");
  if (raw.startsWith("prototype")) {
    state.route = "prototype";
    const screen = decodeURIComponent(raw.split("/")[1] || "");
    if (PROTO_SCREENS.some((item) => item[0] === screen)) state.proto = screen;
    return;
  }
  state.route = PAGES[raw] ? raw : "overview";
}

function go(id) {
  state.navOpen = false;
  const next = id === "prototype" ? `prototype/${state.proto || "login"}` : id;
  if (location.hash === `#${next}`) render();
  else location.hash = next;
}

function goProto(screen) {
  state.proto = screen;
  state.navOpen = false;
  const next = `prototype/${screen}`;
  if (location.hash === `#${next}`) render();
  else location.hash = next;
}

function syncBinds() {
  document.querySelectorAll("[data-bind]").forEach((el) => bindAssign(el.dataset.bind, el.value));
}

function selectedSlot() {
  return getSlots().find((slot) => fmtMinutesKey(slot.start) === state.draft.start);
}

function clearStartIfNeeded() {
  const slot = selectedSlot();
  if (!slot || (slot.status !== "available" && slot.status !== "partial")) state.draft.start = "";
}

function chooseSportContext(sportId) {
  if (sportId === "swimming") {
    state.draft.venueId = "saibaba";
    state.draft.courtId = "sb-sw-1";
    state.draft.modeId = "person";
  } else if (sportId === "badminton") {
    state.draft.venueId = "thudiyalur";
    state.draft.courtId = "td-bd-1";
    state.draft.modeId = "person";
  }
  state.draft.sportId = sportId;
  syncDraft();
}

function addRule(form) {
  syncBinds();
  const data = new FormData(form);
  const price = Number(data.get("price"));
  const start = data.get("start");
  const end = data.get("end");
  if (!price || price <= 0 || !start || !end || minutes(end) <= minutes(start)) {
    state.ruleError = "Enter a rate above zero and an end time after the start time.";
    render({ keepScroll: true });
    return;
  }
  state.customRules.push({
    venueId: state.pricingVenue,
    sportId: state.pricingSport,
    courtId: data.get("court"),
    modeId: data.get("mode"),
    start,
    end,
    price
  });
  state.ruleError = "";
  toast("Pricing rule saved for this session.");
}

function createBooking() {
  const quote = currentQuote();
  const id = `RIAM-${10620 + state.extraBookings.length}`;
  state.extraBookings.unshift({
    id,
    customer: "Arun Kumar",
    phone: `+91 ${state.draft.phone}`,
    venueId: state.draft.venueId,
    sportId: state.draft.sportId,
    courtId: state.draft.courtId,
    date: state.draft.date,
    start: state.draft.start,
    end: fmtMinutesKey(minutes(state.draft.start) + state.draft.duration),
    duration: state.draft.duration,
    modeId: state.draft.modeId,
    side: state.draft.modeId === "half" ? "B" : "",
    headcount: state.draft.headcount,
    amount: Math.round(quote.total),
    paymentStatus: "Paid",
    bookingStatus: "Confirmed",
    method: "UPI",
    createdAt: "1 Oct 2026, 1:13 PM",
    txn: `pay_demo_${id.slice(-5)}`,
    gateway: "Razorpay",
    refund: "None"
  });
  state.draft.bookingId = id;
  state.draft.payment = "success";
  goProto("success");
}

const handlers = {
  stop() {},
  nav(el) { go(el.dataset.id); },
  present() {
    state.presentation = true;
    state.slide = 0;
    render({ keepScroll: true });
  },
  "close-pres"() {
    state.presentation = false;
    render({ keepScroll: true });
  },
  slide(el) {
    const next = state.slide + Number(el.dataset.dir);
    if (next < 0 || next >= SLIDES.length) return;
    state.slide = next;
    render({ keepScroll: true });
  },
  "slide-to"(el) {
    state.slide = Number(el.dataset.index);
    render({ keepScroll: true });
  },
  "exit-to"(el) {
    state.presentation = false;
    go(el.dataset.id);
  },
  "open-nav"() {
    state.navOpen = true;
    render({ keepScroll: true });
  },
  "close-nav"() {
    state.navOpen = false;
    render({ keepScroll: true });
  },
  "close-modal"(el, event) {
    if (el.classList.contains("modal-back") && event.target !== el) return;
    state.modal = null;
    render({ keepScroll: true });
  },
  "modal-yes"() {
    const action = state.modal && state.modal.then;
    if (action) action();
  },
  journey(el) {
    state.journey = Number(el.dataset.index);
    render({ keepScroll: true });
  },
  "venue-tab"(el) {
    state.venueTab = el.dataset.tab;
    render({ keepScroll: true });
  },
  "tree-sport"(el) {
    state.treeSport = el.dataset.sport;
    state.courtFocus = "";
    render({ keepScroll: true });
  },
  "focus-court"(el) {
    state.courtFocus = el.dataset.court;
    render({ keepScroll: true });
  },
  "set-duration"(el) {
    state.draft.duration = Number(el.dataset.mins);
    clearStartIfNeeded();
    render({ keepScroll: true });
  },
  "set-mode"(el) {
    state.draft.modeId = el.dataset.mode;
    clearStartIfNeeded();
    render({ keepScroll: true });
  },
  "pick-date"(el) {
    state.draft.date = el.dataset.date;
    state.draft.explain = "";
    clearStartIfNeeded();
    render({ keepScroll: true });
  },
  "shift-month"(el) {
    const current = parseDate(state.draft.date);
    const next = new Date(current.getFullYear(), current.getMonth() + Number(el.dataset.dir), 1);
    state.draft.date = dateKey(next);
    clearStartIfNeeded();
    render({ keepScroll: true });
  },
  "pick-slot"(el) {
    const status = el.dataset.status;
    if (status === "available" || status === "partial") {
      state.draft.start = el.dataset.start;
      state.draft.explain = status === "partial" ? el.dataset.reason : "";
    } else {
      state.draft.explain = el.dataset.reason;
    }
    render({ keepScroll: true });
  },
  headcount(el) {
    state.draft.headcount = Math.max(1, Math.min(30, state.draft.headcount + Number(el.dataset.dir)));
    if (state.draft.headcount < 8) state.draft.discountApplied = false;
    render({ keepScroll: true });
  },
  "apply-code"() {
    syncBinds();
    if (state.draft.discountCode.trim().toUpperCase() === DEMO_CODE) {
      state.draft.discountApplied = true;
      state.draft.discountError = "";
    } else {
      state.draft.discountApplied = false;
      state.draft.discountError = "That code is not active. The walkthrough code is RIAM8.";
    }
    render({ keepScroll: true });
  },
  "send-otp"() {
    syncBinds();
    state.draft.phone = String(state.draft.phone).replace(/\D/g, "");
    if (!/^\d{10}$/.test(state.draft.phone)) {
      state.draft.otpError = "Enter a 10-digit mobile number.";
      state.draft.otpSent = false;
      render({ keepScroll: true });
      return;
    }
    state.draft.otpError = "";
    state.draft.otpSending = true;
    render({ keepScroll: true });
    setTimeout(() => {
      state.draft.otpSending = false;
      state.draft.otpSent = true;
      render({ keepScroll: true });
    }, 500);
  },
  "verify-otp"() {
    syncBinds();
    if (state.draft.otp !== DEMO_OTP) {
      state.draft.otpError = "That code does not match. The walkthrough code is 482913.";
    } else {
      state.draft.otpError = "";
      state.draft.authed = true;
      state.draft.authProvider = "otp";
      toast("Mobile number verified.");
      return;
    }
    render({ keepScroll: true });
  },
  "google-login"() {
    state.draft.authed = true;
    state.draft.authProvider = "google";
    toast("Continuing with Google. A mobile number is still required for WhatsApp.");
  },
  "save-map"(el) {
    syncBinds();
    const venue = el.dataset.venue;
    if (!isMapsUrl(state.maps[venue])) state.mapsError[venue] = "Enter a full https Google Maps link.";
    else {
      state.mapsError[venue] = "";
      toast("Maps link saved for this review.");
      return;
    }
    render({ keepScroll: true });
  },
  directions(el) {
    const venue = el.dataset.venue;
    const url = state.maps[venue];
    if (!isMapsUrl(url)) {
      state.mapsError[venue] = "Save a valid Google Maps link first.";
      render({ keepScroll: true });
      return;
    }
    window.open(url, "_blank", "noopener");
  },
  "go-pay"() {
    syncBinds();
    state.draft.phone = String(state.draft.phone).replace(/\D/g, "");
    syncDraft();
    const slot = selectedSlot();
    if (!slot || (slot.status !== "available" && slot.status !== "partial")) {
      toast("Choose an available slot before payment.");
      return;
    }
    if (currentQuote().total == null) {
      toast("This resource still needs a confirmed rate.");
      return;
    }
    if (!/^\d{10}$/.test(state.draft.phone)) {
      toast("Enter a 10-digit mobile number for the WhatsApp confirmation.");
      goProto("summary");
      return;
    }
    state.draft.payment = "idle";
    goProto("payment");
  },
  "pay-now"() {
    state.draft.payment = "processing";
    render({ keepScroll: true });
    setTimeout(createBooking, 900);
  },
  "pay-fail"() {
    state.draft.payment = "processing";
    render({ keepScroll: true });
    setTimeout(() => {
      state.draft.payment = "failed";
      render({ keepScroll: true });
    }, 700);
  },
  "pay-preview"(el) {
    state.payPreview = el.dataset.stage;
    render({ keepScroll: true });
  },
  "toggle-razorpay"() {
    state.razorpayMode = state.razorpayMode === "test" ? "live-preview" : "test";
    render({ keepScroll: true });
  },
  "toggle-overnight"() {
    state.showOvernight = !state.showOvernight;
    clearStartIfNeeded();
    render({ keepScroll: true });
  },
  "toggle-wednesday"() {
    state.swim.closedDays = state.swim.closedDays.includes(3)
      ? state.swim.closedDays.filter((day) => day !== 3)
      : state.swim.closedDays.concat(3);
    clearStartIfNeeded();
    render({ keepScroll: true });
  },
  "band-venue"(el) {
    state.pricingVenue = el.dataset.venue;
    render({ keepScroll: true });
  },
  "calc-sport"(el) {
    chooseSportContext(el.dataset.sport);
    render({ keepScroll: true });
  },
  "load-example"(el) {
    state.draft.venueId = el.dataset.venue;
    state.draft.sportId = el.dataset.sport;
    state.draft.courtId = el.dataset.court;
    syncDraft();
    render({ keepScroll: true });
  },
  "example-mode"(el) {
    state.draft.venueId = el.dataset.venue;
    state.draft.sportId = el.dataset.sport;
    state.draft.courtId = el.dataset.court;
    state.draft.modeId = el.dataset.mode;
    syncDraft();
    render({ keepScroll: true });
  },
  tracker(el) {
    state.trackerFilter = el.dataset.filter;
    render({ keepScroll: true });
  },
  "bug-toggle"(el, event) {
    event.preventDefault();
    state.bugChecked = false;
    state.bugNote = "Saving…";
    render({ keepScroll: true });
    setTimeout(() => {
      state.bugChecked = true;
      state.bugNote = "The success message appeared, and Cricket at Saibaba came back.";
      render({ keepScroll: true });
    }, 700);
  },
  "fix-toggle"(el, event) {
    event.preventDefault();
    state.fixChecked = !state.fixChecked;
    render({ keepScroll: true });
  },
  decision(el) {
    state.decisions[el.dataset.id] = el.dataset.status;
    saveSession();
    render({ keepScroll: true });
  },
  "clear-filters"() {
    state.bookingFilter = { venue: "all", sport: "all", court: "all", pay: "all", status: "all", date: "", q: "" };
    render({ keepScroll: true });
  },
  "ask-deactivate"(el) {
    const court = courtById(el.dataset.court);
    state.modal = {
      title: `Deactivate ${court.name}?`,
      body: "Deactivation preserves historical booking references. The court leaves the customer list and stays attached to past bookings.",
      confirm: "Deactivate court",
      danger: true,
      then() {
        if (!state.inactiveIds.includes(court.id)) state.inactiveIds.push(court.id);
        if (state.draft.courtId === court.id) syncDraft();
        state.modal = null;
        toast(`${court.name} deactivated. Linked bookings were kept.`);
      }
    };
    render({ keepScroll: true });
  },
  "activate-court"(el) {
    state.inactiveIds = state.inactiveIds.filter((id) => id !== el.dataset.court);
    toast("Court activated for new bookings.");
  },
  "explain-delete"() {
    state.modal = {
      title: "This record cannot be deleted",
      body: "Existing bookings may reference it. Keep the deactivated legacy service so those bookings still resolve.",
      confirm: "Keep the record",
      then() {
        state.modal = null;
        render({ keepScroll: true });
      }
    };
    render({ keepScroll: true });
  },
  proto(el) { goProto(el.dataset.screen); },
  "proto-after-mode"() {
    const mode = modeById(state.draft.sportId, state.draft.modeId);
    goProto(mode && mode.pricing === "person" ? "headcount" : "summary");
  },
  "choose-venue"(el) {
    state.draft.venueId = el.dataset.venue;
    syncDraft();
    goProto(el.dataset.next || "sport");
  },
  "choose-sport"(el) {
    state.draft.sportId = el.dataset.sport;
    syncDraft();
    goProto("court");
  },
  "choose-court"(el) {
    state.draft.courtId = el.dataset.court;
    syncDraft();
    goProto("calendar");
  },
  "admin-jump"(el) {
    goProto(ADMIN_JUMP[el.dataset.title] || "admin-home");
  },
  download() {
    const quote = currentQuote();
    const id = state.draft.bookingId || "RIAM-10601";
    const lines = [
      "RIAM Sports booking confirmation",
      `Booking ID: ${id}`,
      `Venue: ${venueById(state.draft.venueId).name}`,
      `Sport: ${sportById(state.draft.sportId).name}`,
      `Court: ${courtById(state.draft.courtId)?.name || ""}`,
      `Date: ${fmtDate(state.draft.date)}`,
      `Time: ${state.draft.start ? fmtTime(minutes(state.draft.start)) : ""}`,
      `Duration: ${state.draft.duration} minutes`,
      `Amount: ${quote.total == null ? "Pending" : inr(quote.total)}`
    ];
    const file = new Blob([lines.join("\n")], { type: "text/plain" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(file);
    link.download = `${id}.txt`;
    link.click();
    URL.revokeObjectURL(link.href);
    toast("Confirmation downloaded.");
  }
};

document.addEventListener("click", (event) => {
  const el = event.target.closest("[data-action]");
  if (!el || el.matches("select")) return;
  const handler = handlers[el.dataset.action];
  if (handler) handler(el, event);
});

document.addEventListener("input", (event) => {
  const el = event.target;
  if (!el.dataset.bind) return;
  bindAssign(el.dataset.bind, el.value);
  if (el.dataset.live === "render") render({ keepScroll: true });
});

document.addEventListener("change", (event) => {
  const el = event.target;
  if (el.dataset.draft) {
    state.draft[el.dataset.draft] = el.value;
    syncDraft();
    state.draft.explain = "";
    clearStartIfNeeded();
    render({ keepScroll: true });
  }
  if (el.dataset.filter) {
    state.bookingFilter[el.dataset.filter] = el.value;
    if (el.dataset.filter === "venue" || el.dataset.filter === "sport") state.bookingFilter.court = "all";
    render({ keepScroll: true });
  }
  if (el.dataset.api) {
    state.apiFields[el.dataset.api] = el.checked;
    saveSession();
  }
  if (el.dataset.action === "pricing-venue") {
    state.pricingVenue = el.value;
    const sports = sportsAt(state.pricingVenue, true);
    if (!sports.some((sport) => sport.id === state.pricingSport)) state.pricingSport = sports[0].id;
    render({ keepScroll: true });
  }
  if (el.dataset.action === "pricing-sport") {
    state.pricingSport = el.value;
    render({ keepScroll: true });
  }
  if (el.dataset.action === "proto-select") goProto(el.value);
});

document.addEventListener("submit", (event) => {
  const form = event.target.closest('form[data-action="add-rule"]');
  if (!form) return;
  event.preventDefault();
  addRule(form);
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    if (state.modal) {
      state.modal = null;
      render({ keepScroll: true });
      return;
    }
    if (state.presentation) {
      state.presentation = false;
      render({ keepScroll: true });
      return;
    }
    if (state.navOpen) {
      state.navOpen = false;
      render({ keepScroll: true });
    }
  }
  if (!state.presentation || event.target.matches("input, textarea, select")) return;
  if (event.key === "ArrowRight") handlers.slide({ dataset: { dir: "1" } });
  if (event.key === "ArrowLeft") handlers.slide({ dataset: { dir: "-1" } });
});

window.addEventListener("hashchange", () => {
  readHash();
  render();
});

readHash();
if (!location.hash) location.replace("#overview");
render();
