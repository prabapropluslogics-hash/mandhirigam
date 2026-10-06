const NAV = [
  ["Plan", [
    ["overview", "Project Overview"],
    ["roadmap", "Sprint Roadmap"],
    ["timeline", "Week-by-Week"],
    ["sprints", "Sprint Details"]
  ]],
  ["Build", [
    ["modules", "Module Explorer"],
    ["frontend", "Frontend"],
    ["backend", "Backend"],
    ["api", "API"],
    ["database", "Database"],
    ["integrations", "Integrations"],
    ["workflows", "Business Logic"]
  ]],
  ["Control", [
    ["dependencies", "Dependencies"],
    ["feasibility", "Technical Feasibility"],
    ["deliverables", "Sprint Deliverables"],
    ["flow", "Development Flow"],
    ["summary", "Timeline Summary"],
    ["notes", "Important Notes"],
    ["handover", "Handover & QA"]
  ]]
];

const state = {
  route: "overview",
  sprintId: 1,
  moduleId: PLAN.modules[0].id,
  openDays: {},
  present: false,
  slide: 0,
  navOpen: false,
  techTab: "frontend"
};

function $(sel, root) { return (root || document).querySelector(sel); }

function badgeClass(status) {
  return "badge b-" + String(status || "planned").toLowerCase().replace(/[^a-z]+/g, "-");
}

function bullets(items) {
  if (!items || !items.length) return "<p class='muted'>None named in this plan.</p>";
  return `<ul class="clean">${items.map((item) => `<li>${esc(item)}</li>`).join("")}</ul>`;
}

function flow(steps) {
  return `<div class="flow">${steps.map((step) => `<b>${esc(step)}</b>`).join("")}</div>`;
}

function sprintById(id) {
  return PLAN.sprints.find((sprint) => sprint.id === Number(id)) || PLAN.sprints[0];
}

function moduleById(id) {
  return PLAN.modules.find((mod) => mod.id === id) || PLAN.modules[0];
}

function dayKey(sprint, task) { return sprint.id + "-" + task.n; }

function renderTask(sprint, task) {
  const key = dayKey(sprint, task);
  const open = state.openDays[key] !== false;
  let body = "";
  if (task.feasibility) {
    body = `<div class="warn"><strong>Technical Feasibility — To Be Confirmed.</strong><p>This requirement has not yet been researched and confirmed. It is not a confirmed development commitment.</p></div>${bullets(task.items)}`;
  } else if (task.groups) {
    body = `<div class="groups">${task.groups.map((group) => `<div class="group"><h4>${esc(group.label)}</h4>${bullets(group.items)}</div>`).join("")}</div>`;
  } else {
    body = bullets(task.items);
  }
  if (task.flow) body += `<p class="mini-label">Agreed core flow</p>${flow(task.flow)}`;
  if (task.notes) body += `<p class="mini-label">${esc(task.noteTitle || "Notes")}</p>${bullets(task.notes)}`;
  return `<article class="day">
    <header>
      <button type="button" data-action="toggle-day" data-key="${key}"><strong>${esc(task.day)} — ${esc(task.name)}</strong></button>
      ${task.status ? `<span class="${badgeClass(task.status)}">${esc(task.status)}</span>` : ""}
    </header>
    <div class="${open ? "" : "hidden"}">${body}</div>
  </article>`;
}

function pageOverview() {
  return `<section>
    <div class="hero">
      <p class="kicker">Phase 1 · Client development plan</p>
      <h2>${esc(PLAN.project)}</h2>
      <p class="kicker">${esc(PLAN.title)}</p>
      <p>${esc(PLAN.subtitle)}</p>
      <p>${esc(PLAN.overview.timeline)}</p>
      <div class="stats">
        <div class="stat"><b>40</b><span>Development days</span></div>
        <div class="stat"><b>10</b><span>QA days, separate</span></div>
        <div class="stat"><b>50</b><span>Working days total</span></div>
        <div class="stat"><b>8</b><span>Development sprints</span></div>
      </div>
    </div>
    <div class="grid cols-2 section-gap">
      <article class="card"><h3>Project objective</h3><p>${esc(PLAN.overview.objective)}</p></article>
      <article class="card"><h3>Development approach</h3><p>${esc(PLAN.overview.approach)}</p></article>
      <article class="card"><h3>Sprint structure</h3><p>${esc(PLAN.overview.sprintStructure)}</p></article>
      <article class="card"><h3>Development sequence</h3><p>${esc(PLAN.overview.sequence)}</p></article>
    </div>
    <article class="panel section-gap">
      <h2>Major modules</h2>
      ${bullets(PLAN.majorModules)}
      <p class="muted">Version, document status, prepared for, and prepared by: ${esc(PLAN.version)}. Date ${esc(PLAN.date)}.</p>
    </article>
  </section>`;
}

function pageRoadmap() {
  return `<section>
    <article class="panel">
      <p class="kicker">Overall sprint roadmap</p>
      <h2>From research to QA handover</h2>
      <div class="roadmap">
        ${PLAN.sprints.map((sprint, index) => `<div class="road">
          <div class="rail"><span class="dot"></span>${index < PLAN.sprints.length ? "<i></i>" : ""}</div>
          <button class="card clicky" type="button" data-action="open-sprint" data-id="${sprint.id}">
            <p class="kicker">Sprint ${esc(sprint.code)} · ${esc(sprint.daysLabel)} · ${esc(sprint.duration)}</p>
            <h3>${esc(sprint.title)}</h3>
            <p>${esc(sprint.modules.join(" · "))}</p>
            <p><strong>Deliverable.</strong> ${esc(sprint.deliverables[0])}</p>
          </button>
        </div>`).join("")}
        <div class="road">
          <div class="rail"><span class="dot"></span></div>
          <button class="card clicky" type="button" data-action="go" data-route="handover">
            <p class="kicker">Separate phase · ${esc(PLAN.qaDuration)}</p>
            <h3>Testing / QA</h3>
            <p>Shown beyond the 40 development days. Final Regression + QA Sign-off.</p>
          </button>
        </div>
      </div>
    </article>
  </section>`;
}

function pageTimeline() {
  return `<section class="grid">
    ${PLAN.sprints.map((sprint) => `<article class="card">
      <p class="kicker">${esc(sprint.week)} · ${esc(sprint.daysLabel)}</p>
      <h3>${esc(sprint.title)}</h3>
      <p><span class="${badgeClass(sprint.status)}">${esc(sprint.status)}</span></p>
      <p>${esc(sprint.objective)}</p>
      <button class="link" type="button" data-action="open-sprint" data-id="${sprint.id}">Open complete sprint details</button>
    </article>`).join("")}
  </section>`;
}

function pageSprints() {
  const sprint = sprintById(state.sprintId);
  return `<section>
    <div class="filters">
      ${PLAN.sprints.map((item) => `<button type="button" class="${item.id === sprint.id ? "on" : ""}" data-action="open-sprint" data-id="${item.id}">${esc(item.week)}</button>`).join("")}
      <button type="button" data-action="expand-sprint">Expand all</button>
      <button type="button" data-action="collapse-sprint">Collapse all</button>
    </div>
    <article class="panel">
      <p class="kicker">Sprint ${esc(sprint.code)} · ${esc(sprint.week)} · ${esc(sprint.daysLabel)}</p>
      <h2>${esc(sprint.title)}</h2>
      <p><span class="${badgeClass(sprint.status)}">${esc(sprint.status)}</span></p>
      <div class="stats">
        <div class="stat"><b>${esc(sprint.duration.replace(" Working Days", ""))}</b><span>Working days</span></div>
        <div class="stat"><b>${sprint.tasks.length}</b><span>Day blocks</span></div>
        <div class="stat"><b>${sprint.modules.length}</b><span>Primary modules</span></div>
        <div class="stat"><b>1</b><span>Sprint deliverable</span></div>
      </div>
      <h3>Objective</h3>
      <p>${esc(sprint.objective)}</p>
      <h3>Primary modules</h3>
      ${bullets(sprint.modules)}
      <h3>Development tasks</h3>
      ${sprint.tasks.map((task) => renderTask(sprint, task)).join("")}
      ${sprint.technical ? `<h3>Technical work</h3><div class="groups">${Object.entries({ frontend: "Frontend", backend: "Backend", api: "API", database: "Database", other: "Related analysis" }).filter(([key]) => sprint.technical[key]).map(([key, label]) => `<div class="group"><h4>${label}</h4>${bullets(sprint.technical[key])}</div>`).join("")}</div>` : ""}
      ${sprint.business ? `<h3>Business logic</h3>${bullets(sprint.business)}` : ""}
      ${sprint.integration ? `<h3>Integration</h3>${bullets(sprint.integration)}` : ""}
      ${sprint.dependencies ? `<h3>Dependencies</h3>${bullets(sprint.dependencies)}` : ""}
      <h3>Deliverables</h3>
      ${bullets(sprint.deliverables)}
      ${sprint.notes ? `<h3>Important notes</h3>${sprint.notes.map((note) => `<div class="warn"><p>${esc(note)}</p></div>`).join("")}` : ""}
    </article>
  </section>`;
}

function union(groups) {
  const seen = new Set();
  const out = [];
  groups.flat().forEach((item) => {
    if (!item || seen.has(item)) return;
    seen.add(item);
    out.push(item);
  });
  return out;
}

function pageModules() {
  const mod = moduleById(state.moduleId);
  const tasks = union([mod.features, mod.frontend, mod.backend, mod.api, mod.database, mod.integration, mod.business]);
  const blocks = [
    ["Purpose", null, `<p>${esc(mod.purpose)}</p>`],
    ["Features", mod.features],
    ["Sub-modules", mod.subModules],
    ["Tasks", tasks],
    ["Frontend", mod.frontend],
    ["Backend", mod.backend],
    ["API", mod.api],
    ["Database", mod.database],
    ["Integration", mod.integration],
    ["Business rules", mod.business],
    ["Dependencies", mod.dependencies],
    ["Deliverables", mod.deliverables]
  ];
  return `<section class="split module-split">
    <div class="filters" style="align-content: start">${PLAN.modules.map((item) => `<button type="button" class="${item.id === mod.id ? "on" : ""}" data-action="open-module" data-id="${esc(item.id)}">${esc(item.name)}</button>`).join("")}</div>
    <article class="panel">
      <p class="kicker">${esc(mod.sprints.join(" · "))}</p>
      <h2>${esc(mod.name)}</h2>
      ${blocks.map(([label, items, custom]) => `<h3>${esc(label)}</h3>${custom || bullets(items)}`).join("")}
    </article>
  </section>`;
}

function scopePage(title, intro, groups) {
  return `<section><article class="panel"><p class="kicker">Consolidated scope</p><h2>${esc(title)}</h2><p>${esc(intro)}</p>
    <div class="grid cols-2">${groups.map((group) => `<article class="card"><h3>${esc(group.group)}</h3>${bullets(group.items)}</article>`).join("")}</div>
  </article></section>`;
}

function pageApi() {
  return `<section><article class="panel"><p class="kicker">Named APIs only</p><h2>API development scope</h2>
    <p>Each row uses an API or API group named in the plan.</p>
    <div class="table-wrap"><table><thead><tr><th>API / Function</th><th>Purpose</th><th>Used by</th><th>Module</th><th>Data flow</th><th>Dependencies</th><th>Status</th></tr></thead><tbody>
      ${PLAN.apis.map((api) => `<tr><td>${esc(api.name)}<br><span class="muted">${esc(api.sprint)}</span></td><td>${esc(api.purpose)}</td><td>${esc(api.usedBy)}</td><td>${esc(api.module)}</td><td>${esc(api.flow)}</td><td>${esc(api.dependency)}</td><td><span class="${badgeClass(api.status)}">${esc(api.status)}</span></td></tr>`).join("")}
    </tbody></table></div></article></section>`;
}

function pageDatabase() {
  return `<section><div class="warn"><strong>Database structure to be finalized during technical analysis.</strong><p>${esc(PLAN.database.statement)}</p></div>
    <div class="grid cols-2 section-gap">${PLAN.database.entities.map((entity) => `<article class="card"><h3>${esc(entity.name)}</h3><p>${esc(entity.purpose)}</p><p><strong>Relationships.</strong> ${esc(entity.relationships)}</p><p><strong>CRUD.</strong> ${esc(entity.crud)}</p><p class="muted">${esc(entity.usedBy)} · ${esc(entity.sprint)}</p>${entity.fields ? bullets(entity.fields) : ""}</article>`).join("")}</div></section>`;
}

function pageIntegrations() {
  return `<section><article class="panel"><h2>Integration matrix</h2><div class="table-wrap"><table><thead><tr><th>Integration</th><th>Purpose</th><th>Module</th><th>Requirement</th><th>Dependency</th><th>Status</th></tr></thead><tbody>
    ${PLAN.integrations.map((row) => `<tr><td>${esc(row.name)}</td><td>${esc(row.purpose)}</td><td>${esc(row.module)}</td><td>${esc(row.requirement)}</td><td>${esc(row.dependency)}</td><td><span class="${badgeClass(row.status)}">${esc(row.status)}</span></td></tr>`).join("")}
  </tbody></table></div></article></section>`;
}

function pageWorkflows() {
  return `<section class="grid">
    <article class="panel"><h2>Student journey</h2><p>Studied on Day 2, with general counselling and student data collection.</p>${flow(PLAN.studentJourney)}${bullets(["General counselling flow", "Student data collection requirements"])}</article>
    <article class="panel"><h2>Enquiry steps</h2>${flow(PLAN.enquirySteps)}<p>Includes validation/error states, validation, submission, and an enquiry status foundation.</p></article>
    <article class="panel"><h2>Agreed lead-routing flow</h2><p>Implemented in Sprint 6.</p>${flow(PLAN.leadFlow)}</article>
    <article class="panel"><h2>Business rules in Sprint 7</h2>${bullets(["Qualification/course rules", "College matching rules", "Enquiry rules", "Lead priority", "College assignment", "Status transitions", "Duplicate/invalid data handling", "Recommendation/business-rule implementation based on finalized requirements"])}</article>
  </section>`;
}

function pageDependencies() {
  return `<section class="grid cols-2">${PLAN.dependencies.map((row) => `<article class="card"><p class="kicker">${esc(row.type)} · ${esc(row.sprint)}</p><h3>${esc(row.name)}</h3><p>${esc(row.detail)}</p><span class="${badgeClass(row.status)}">${esc(row.status)}</span></article>`).join("")}</section>`;
}

function pageFeasibility() {
  const item = PLAN.feasibility;
  return `<section><article class="warn">
    <p class="kicker">${esc(item.sprint)}</p>
    <h2>${esc(item.title)}</h2>
    <p><span class="${badgeClass(item.status)}">${esc(item.status)}</span></p>
    <h3>Requirement</h3><p>${esc(item.requirement)}</p>
    <h3>Why confirmation is required</h3><p>${esc(item.why)}</p>
    <h3>Validation required</h3>${bullets(item.validation)}
    <h3>Client statement</h3><blockquote>${esc(item.statement)}</blockquote>
    <h3>Implementation</h3><p><strong>${esc(item.implementation)}</strong></p>
  </article></section>`;
}

function pageDeliverables() {
  return `<section class="grid cols-2">${PLAN.sprints.map((sprint) => `<article class="card"><p class="kicker">Sprint ${esc(sprint.code)} · ${esc(sprint.week)}</p><h3>${esc(sprint.title)}</h3><p>${esc(sprint.deliverables[0])}</p><button class="link" type="button" data-action="open-sprint" data-id="${sprint.id}">View sprint</button></article>`).join("")}
    <article class="card"><p class="kicker">Separate phase</p><h3>QA – 10 Working Days</h3><p>Final Regression + QA Sign-off</p></article></section>`;
}

function pageFlow() {
  return `<section><article class="panel"><p class="kicker">Overall development completion flow</p><h2>How the sprints lead forward</h2>${flow(PLAN.completionFlow.map((step) => step.sprint + " — " + step.label))}</article></section>`;
}

function pageSummary() {
  return `<section><article class="panel"><h2>Timeline summary</h2><div class="table-wrap"><table><thead><tr><th>Sprint</th><th>Duration</th><th>Focus</th><th>Major work</th><th>Deliverable</th><th>Status</th></tr></thead><tbody>
    ${PLAN.sprints.map((s) => `<tr><td>${esc(s.week)}</td><td>${esc(s.duration)}</td><td>${esc(s.distributionFocus)}</td><td>${esc(s.title)}</td><td>${esc(s.deliverables[0])}</td><td><span class="${badgeClass(s.status)}">${esc(s.status)}</span></td></tr>`).join("")}
    <tr><td>QA / Testing</td><td>${esc(PLAN.qaDuration)}</td><td>Separate Testing Phase</td><td>Listed in Handover & QA</td><td>Final Regression + QA Sign-off</td><td><span class="badge">PLANNED</span></td></tr>
    <tr><td>Overall</td><td>${esc(PLAN.totalDuration)}</td><td colspan="4">40 Working Days development + 10 Working Days testing / QA</td></tr>
  </tbody></table></div>
  <h3>Development distribution</h3>
  <div class="table-wrap"><table><thead><tr><th>Week</th><th>Focus</th><th>Days</th></tr></thead><tbody>
    ${PLAN.sprints.map((s) => `<tr><td>${esc(s.week)}</td><td>${esc(s.distributionFocus)}</td><td>5</td></tr>`).join("")}
    <tr><td>Total Development</td><td></td><td>40 Days</td></tr>
    <tr><td>QA / Testing</td><td>Separate Testing Phase</td><td>10 Days</td></tr>
    <tr><td>Overall</td><td></td><td>50 Working Days</td></tr>
  </tbody></table></div></article></section>`;
}

function pageNotes() {
  return `<section class="grid">${PLAN.notes.map((note) => `<article class="warn"><h3>${esc(note.title)}</h3><p>${esc(note.body)}</p></article>`).join("")}</section>`;
}

function pageHandover() {
  return `<section class="grid">
    <article class="panel"><h2>Expected at the end of development</h2>${bullets(PLAN.handover.developmentComplete)}</article>
    <article class="panel"><h2>After development</h2>${flow(PLAN.handover.flow)}<p>${esc(PLAN.handover.uatNote)}</p><p>${esc(PLAN.handover.releaseNote)}</p></article>
    <article class="panel"><h2>${esc(PLAN.qa.title)}</h2><p>${esc(PLAN.qa.note)}</p><div class="table-wrap"><table><thead><tr><th>Days</th><th>Testing activity</th></tr></thead><tbody>
      ${PLAN.qa.rows.map((row) => `<tr><td>${esc(row.days)}</td><td>${esc(row.activity)}</td></tr>`).join("")}
    </tbody></table></div></article>
  </section>`;
}

const PAGES = {
  overview: pageOverview,
  roadmap: pageRoadmap,
  timeline: pageTimeline,
  sprints: pageSprints,
  modules: pageModules,
  frontend: () => scopePage("Frontend development", "Grouped from screens, components, forms, and integration work named in the plan.", PLAN.frontendScope),
  backend: () => scopePage("Backend development", "Grouped from authentication, business rules, CRUD, validation, status, and completion work named in the plan.", PLAN.backendScope),
  api: pageApi,
  database: pageDatabase,
  integrations: pageIntegrations,
  workflows: pageWorkflows,
  dependencies: pageDependencies,
  feasibility: pageFeasibility,
  deliverables: pageDeliverables,
  flow: pageFlow,
  summary: pageSummary,
  notes: pageNotes,
  handover: pageHandover
};

function titleFor(route) {
  for (const group of NAV) {
    const found = group[1].find((item) => item[0] === route);
    if (found) return found[1];
  }
  return "Overview";
}

function mount() {
  const nav = NAV.map(([label, items]) => `<p class="nav-label">${label}</p>${items.map(([id, name]) => `<button type="button" class="nav" data-nav="${id}" data-action="go" data-route="${id}">${esc(name)}</button>`).join("")}`).join("");
  document.getElementById("app").innerHTML = `
    <div class="shell" id="shell">
      <aside class="sidebar"><div class="brand"><span class="mark">B</span><span><strong>Best Academic</strong><em>Sprint plan</em></span></div><nav>${nav}</nav></aside>
      <div class="scrim" data-action="close-nav"></div>
      <main class="main">
        <header class="topbar">
          <button class="icon-btn menu-btn" type="button" data-action="open-nav">Menu</button>
          <h1 id="page-title">Project Overview</h1>
          <a class="btn" href="../../Docs/Best-Academic-Education-Portal-Weekly-Sprint-Development-Plan.html">Formal document</a>
          <button class="btn primary" type="button" data-action="present">Presentation mode</button>
        </header>
        <div class="outlet" id="outlet"></div>
      </main>
    </div>
    <div id="pres-root"></div>`;
}

function render() {
  const shell = document.getElementById("shell");
  if (!shell) mount();
  document.querySelectorAll("[data-nav]").forEach((button) => button.classList.toggle("active", button.dataset.nav === state.route));
  document.getElementById("shell").classList.toggle("nav-open", state.navOpen);
  document.getElementById("page-title").textContent = titleFor(state.route);
  document.title = PLAN.project + " — " + titleFor(state.route);
  document.getElementById("outlet").innerHTML = (PAGES[state.route] || pageOverview)();
  renderPresentation();
}

function slides() {
  const sprintSlides = PLAN.sprints.map((sprint) => ({
    kicker: `Sprint ${sprint.code} · ${sprint.week} · ${sprint.daysLabel}`,
    title: sprint.title,
    html: `<p>${esc(sprint.objective)}</p><p><span class="${badgeClass(sprint.status)}">${esc(sprint.status)}</span></p>${sprint.tasks.map((task) => renderTask(sprint, task)).join("")}<div class="card"><strong>Deliverable.</strong> ${esc(sprint.deliverables[0])}</div>`
  }));
  return [
    { kicker: "Phase 1", title: PLAN.project, html: `<p>${esc(PLAN.title)}</p><p>${esc(PLAN.subtitle)}</p><p>${esc(PLAN.overview.timeline)}</p>` },
    { kicker: "Overview", title: "What this plan covers", html: `<p>${esc(PLAN.overview.objective)}</p><p>${esc(PLAN.overview.approach)}</p>` },
    { kicker: "Roadmap", title: "Eight development sprints, then QA", html: flow(PLAN.completionFlow.map((step) => step.sprint + " — " + step.label)) },
    ...sprintSlides,
    { kicker: "Business flow", title: "Agreed lead routing", html: flow(PLAN.leadFlow) },
    { kicker: "Technical feasibility", title: PLAN.feasibility.title, html: `<div class="warn"><p>${esc(PLAN.feasibility.statement)}</p><p><strong>${esc(PLAN.feasibility.implementation)}</strong></p></div>${bullets(PLAN.feasibility.validation)}` },
    { kicker: "Close", title: "Development complete, then QA", html: flow(PLAN.handover.flow) + bullets(PLAN.qa.rows.map((row) => row.days + " — " + row.activity)) }
  ];
}

function renderPresentation() {
  const root = document.getElementById("pres-root");
  if (!state.present) { root.innerHTML = ""; return; }
  const deck = slides();
  state.slide = Math.max(0, Math.min(state.slide, deck.length - 1));
  const slide = deck[state.slide];
  root.innerHTML = `<div class="pres" role="dialog" aria-label="Presentation">
    <header><span>${esc(PLAN.project)}</span><span>${state.slide + 1} / ${deck.length}</span></header>
    <div class="slide"><p class="kicker">${esc(slide.kicker)}</p><h2>${esc(slide.title)}</h2>${slide.html}</div>
    <footer>
      <button class="btn" type="button" data-action="prev-slide">Previous</button>
      <div class="progress">${deck.map((_, i) => `<i class="${i === state.slide ? "on" : ""}"></i>`).join("")}</div>
      <button class="btn" type="button" data-action="next-slide">Next</button>
      <button class="btn" type="button" data-action="close-present">Exit</button>
    </footer>
  </div>`;
}

function setRoute(route) {
  state.route = route;
  state.navOpen = false;
  const hash = route === "sprints" ? `#/sprints/${state.sprintId}` : route === "modules" ? `#/modules/${state.moduleId}` : `#/${route}`;
  if (location.hash !== hash) location.hash = hash;
  else render();
}

function readHash() {
  const parts = location.hash.replace(/^#\/?/, "").split("/").filter(Boolean);
  state.route = parts[0] || "overview";
  if (!PAGES[state.route]) state.route = "overview";
  if (state.route === "sprints" && parts[1]) state.sprintId = Number(parts[1]) || 1;
  if (state.route === "modules" && parts[1]) state.moduleId = parts[1];
  render();
}

document.addEventListener("click", (event) => {
  const target = event.target.closest("[data-action]");
  if (!target) return;
  const action = target.dataset.action;
  if (action === "go") setRoute(target.dataset.route);
  if (action === "open-nav") { state.navOpen = true; render(); }
  if (action === "close-nav") { state.navOpen = false; render(); }
  if (action === "open-sprint") {
    state.sprintId = Number(target.dataset.id);
    setRoute("sprints");
  }
  if (action === "open-module") {
    state.moduleId = target.dataset.id;
    setRoute("modules");
  }
  if (action === "toggle-day") {
    const key = target.dataset.key;
    state.openDays[key] = state.openDays[key] === false;
    render();
  }
  if (action === "expand-sprint") {
    sprintById(state.sprintId).tasks.forEach((task) => { state.openDays[dayKey(sprintById(state.sprintId), task)] = true; });
    render();
  }
  if (action === "collapse-sprint") {
    sprintById(state.sprintId).tasks.forEach((task) => { state.openDays[dayKey(sprintById(state.sprintId), task)] = false; });
    render();
  }
  if (action === "present") { state.present = true; state.slide = 0; render(); }
  if (action === "close-present") { state.present = false; render(); }
  if (action === "next-slide") { state.slide += 1; renderPresentation(); }
  if (action === "prev-slide") { state.slide = Math.max(0, state.slide - 1); renderPresentation(); }
});

document.addEventListener("keydown", (event) => {
  if (!state.present) return;
  if (event.key === "ArrowRight") { state.slide += 1; renderPresentation(); }
  if (event.key === "ArrowLeft") { state.slide = Math.max(0, state.slide - 1); renderPresentation(); }
  if (event.key === "Escape") { state.present = false; render(); }
});

window.addEventListener("hashchange", readHash);
readHash();
