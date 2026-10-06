function esc(value) {
  return String(value == null ? "" : value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function badge(status) {
  const key = String(status || "PLANNED").toLowerCase().replace(/[^a-z]+/g, "-");
  return `<span class="badge b-${key}">${esc(status)}</span>`;
}

function list(items) {
  if (!items || !items.length) return "";
  return `<ul>${items.map((item) => `<li>${esc(item)}</li>`).join("")}</ul>`;
}

function taskBlocks(sprint) {
  return sprint.tasks.map((task) => {
    const head = `<h3><span>${esc(task.day)}</span> ${esc(task.name)} ${task.status ? badge(task.status) : ""}</h3>`;
    let body = "";
    if (task.feasibility) {
      body += `<div class="warn"><strong>Technical Feasibility — To Be Confirmed.</strong> This requirement has not yet been researched and confirmed. It is not a confirmed development commitment. Research and confirm:</div>`;
      body += list(task.items);
    } else if (task.groups) {
      body += task.groups.map((group) => `<h4>${esc(group.label)}</h4>${list(group.items)}`).join("");
    } else {
      body += list(task.items);
    }
    if (task.flow) {
      body += `<p class="kicker">Agreed core flow</p><div class="flow">${task.flow.map((step, i) => `<span>${esc(step)}</span>${i < task.flow.length - 1 ? '<i>↓</i>' : ""}`).join("")}</div>`;
    }
    if (task.notes) {
      body += `<h4>${esc(task.noteTitle || "Notes")}</h4>${list(task.notes)}`;
    }
    return head + body;
  }).join("");
}

function techBlock(technical) {
  if (!technical) return "";
  const labels = { frontend: "Frontend", backend: "Backend", api: "API", database: "Database", other: "Related analysis" };
  const parts = Object.keys(labels).filter((key) => technical[key] && technical[key].length).map((key) => `<h4>${labels[key]}</h4>${list(technical[key])}`);
  if (!parts.length) return "";
  return `<h3>Technical work</h3>${parts.join("")}`;
}

function optionalBlock(title, items) {
  if (!items || !items.length) return "";
  return `<h3>${esc(title)}</h3>${list(items)}`;
}

function renderFormalDocument() {
  const control = [
    ["Document Name", PLAN.documentName],
    ["Project Name", PLAN.project],
    ["Version", PLAN.version],
    ["Document Status", PLAN.documentStatus],
    ["Prepared For", PLAN.preparedFor],
    ["Prepared By", PLAN.preparedBy],
    ["Development Duration", PLAN.developmentDuration],
    ["QA / Testing Duration", PLAN.qaDuration],
    ["Total Project Working Timeline", PLAN.totalDuration],
    ["Date", PLAN.date],
    ["Last Updated", PLAN.lastUpdated]
  ];

  const sprintSections = PLAN.sprints.map((sprint) => `
    <article class="sprint" id="sprint-${sprint.id}">
      <header class="sprint-head">
        <p>Sprint ${esc(sprint.code)} · ${esc(sprint.week)} · ${esc(sprint.daysLabel)}</p>
        <h2>${esc(sprint.title)}</h2>
        ${badge(sprint.status)}
      </header>
      <div class="meta-row">
        <div><em>Duration</em><strong>${esc(sprint.duration)}</strong></div>
        <div><em>Distribution focus</em><strong>${esc(sprint.distributionFocus)}</strong></div>
      </div>
      <h3>Sprint objective</h3>
      <p>${esc(sprint.objective)}</p>
      <h3>Primary modules</h3>
      ${list(sprint.modules)}
      <h3>Development tasks</h3>
      ${taskBlocks(sprint)}
      ${techBlock(sprint.technical)}
      ${optionalBlock("Business logic", sprint.business)}
      ${optionalBlock("Integration", sprint.integration)}
      ${optionalBlock("Dependencies", sprint.dependencies)}
      <h3>Deliverables</h3>
      ${list(sprint.deliverables)}
      ${optionalBlock("Important notes", sprint.notes)}
      <aside class="deliverable">
        <p>Sprint deliverable</p>
        <strong>${esc(sprint.deliverables[0])}</strong>
      </aside>
    </article>`).join("");

  const moduleSections = PLAN.modules.map((mod) => `
    <article class="module" id="module-${mod.id}">
      <h3>${esc(mod.name)}</h3>
      <p>${esc(mod.purpose)}</p>
      <p class="related">Related sprints: ${esc(mod.sprints.join(", "))}</p>
      <h4>Features</h4>${list(mod.features)}
      <h4>Sub-modules</h4>${list(mod.subModules)}
      ${mod.frontend.length ? `<h4>Frontend work</h4>${list(mod.frontend)}` : ""}
      ${mod.backend.length ? `<h4>Backend work</h4>${list(mod.backend)}` : ""}
      ${mod.api.length ? `<h4>API work</h4>${list(mod.api)}` : ""}
      ${mod.database.length ? `<h4>Database work</h4>${list(mod.database)}` : ""}
      ${mod.integration.length ? `<h4>Integration</h4>${list(mod.integration)}` : ""}
      ${mod.business.length ? `<h4>Business rules</h4>${list(mod.business)}` : ""}
      ${mod.dependencies.length ? `<h4>Dependencies</h4>${list(mod.dependencies)}` : ""}
      <h4>Deliverables</h4>${list(mod.deliverables)}
    </article>`).join("");

  return `
    <section class="cover" id="cover">
      <p class="eyebrow">Phase 1 · Client development plan</p>
      <h1>${esc(PLAN.project)}</h1>
      <p class="subtitle">${esc(PLAN.title)}</p>
      <p class="tagline">${esc(PLAN.subtitle)}</p>
      <hr />
      <p class="lead">${esc(PLAN.overview.timeline)}</p>
      <dl class="cover-meta">
        <dt>Version</dt><dd>${esc(PLAN.version)}</dd>
        <dt>Document Status</dt><dd>${esc(PLAN.documentStatus)}</dd>
        <dt>Prepared For</dt><dd>${esc(PLAN.preparedFor)}</dd>
        <dt>Prepared By</dt><dd>${esc(PLAN.preparedBy)}</dd>
        <dt>Date</dt><dd>${esc(PLAN.date)}</dd>
      </dl>
    </section>

    <section class="content" id="contents">
      <h1 class="sec">Contents</h1>
      <ol>
        <li>Cover</li>
        <li><a href="#control">Document Control</a></li>
        <li><a href="#overview">Project Development Overview</a></li>
        <li><a href="#roadmap">Overall Sprint Roadmap</a></li>
        <li><a href="#sprints">Sprint-wise Detailed Development Plan</a></li>
        <li><a href="#modules">Module-wise Development Breakdown</a></li>
        <li><a href="#frontend">Frontend Development Scope</a></li>
        <li><a href="#backend">Backend Development Scope</a></li>
        <li><a href="#api">API Development Scope</a></li>
        <li><a href="#database">Database / Data Layer Scope</a></li>
        <li><a href="#integrations">Integration Scope</a></li>
        <li><a href="#workflows">Business Logic &amp; Workflow</a></li>
        <li><a href="#dependencies">Dependencies &amp; Client Inputs</a></li>
        <li><a href="#feasibility">Technical Feasibility / TBC Items</a></li>
        <li><a href="#deliverables">Sprint Deliverables</a></li>
        <li><a href="#flow">Overall Development Completion Flow</a></li>
        <li><a href="#summary">Timeline Summary</a></li>
        <li><a href="#notes">Important Notes</a></li>
        <li><a href="#handover">Final Development Handover / Next Phase</a></li>
      </ol>
    </section>

    <section class="content" id="control">
      <h1 class="sec">2. Document Control</h1>
      <table>
        <tbody>
          ${control.map(([k, v]) => `<tr><th>${esc(k)}</th><td>${esc(v)}</td></tr>`).join("")}
        </tbody>
      </table>
      <p class="note">Where a control field was not supplied, this document uses “To Be Confirmed”.</p>
    </section>

    <section class="content" id="overview">
      <h1 class="sec">3. Project Development Overview</h1>
      <h2>Project objective</h2>
      <p>${esc(PLAN.overview.objective)}</p>
      <h2>Development approach</h2>
      <p>${esc(PLAN.overview.approach)}</p>
      <h2>Sprint structure</h2>
      <p>${esc(PLAN.overview.sprintStructure)}</p>
      <h2>Major modules</h2>
      ${list(PLAN.majorModules)}
      <h2>Development sequence</h2>
      <p>${esc(PLAN.overview.sequence)}</p>
      <div class="flow">${PLAN.completionFlow.map((step, i) => `<span><small>${esc(step.sprint)}</small>${esc(step.label)}</span>${i < PLAN.completionFlow.length - 1 ? "<i>↓</i>" : ""}`).join("")}</div>
      <h2>Overall timeline</h2>
      <p>${esc(PLAN.overview.timeline)} Testing / QA is additional to the development duration.</p>
    </section>

    <section class="content" id="roadmap">
      <h1 class="sec">4. Overall Sprint Roadmap</h1>
      <table>
        <thead><tr><th>Sprint / Week</th><th>Focus</th><th>Major modules</th><th>Duration</th><th>Deliverable</th></tr></thead>
        <tbody>
          ${PLAN.sprints.map((s) => `<tr><td>Sprint ${esc(s.code)}<br>${esc(s.week)}</td><td>${esc(s.title)}</td><td>${esc(s.modules.join(", "))}</td><td>${esc(s.duration)}</td><td>${esc(s.deliverables[0])}</td></tr>`).join("")}
          <tr><td>QA</td><td>Testing / QA</td><td>Separate testing phase</td><td>${esc(PLAN.qaDuration)}</td><td>Final Regression + QA Sign-off</td></tr>
        </tbody>
      </table>
    </section>

    <section class="content" id="sprints">
      <h1 class="sec">5. Sprint-wise Detailed Development Plan</h1>
      <p>Each sprint below keeps the day, task, frontend, backend, API, and database items from the source plan. Categories appear only where the source includes them.</p>
      ${sprintSections}
    </section>

    <section class="content" id="modules">
      <h1 class="sec">6. Module-wise Development Breakdown</h1>
      <p>This view regroups the same work by module. Sprint sections remain the day-by-day record.</p>
      ${moduleSections}
    </section>

    <section class="content" id="frontend">
      <h1 class="sec">7. Frontend Development Scope</h1>
      ${PLAN.frontendScope.map((group) => `<h2>${esc(group.group)}</h2>${list(group.items)}`).join("")}
    </section>

    <section class="content" id="backend">
      <h1 class="sec">8. Backend Development Scope</h1>
      ${PLAN.backendScope.map((group) => `<h2>${esc(group.group)}</h2>${list(group.items)}`).join("")}
    </section>

    <section class="content" id="api">
      <h1 class="sec">9. API Development Scope</h1>
      <p>Names below are the APIs and API groups named in the plan. No additional API names have been introduced.</p>
      <table>
        <thead><tr><th>API / Function</th><th>Purpose</th><th>Used by</th><th>Related module</th><th>Data flow</th><th>Dependencies</th><th>Status</th></tr></thead>
        <tbody>
          ${PLAN.apis.map((api) => `<tr><td>${esc(api.name)}<br><small>${esc(api.sprint)}</small></td><td>${esc(api.purpose)}</td><td>${esc(api.usedBy)}</td><td>${esc(api.module)}</td><td>${esc(api.flow)}</td><td>${esc(api.dependency)}</td><td>${badge(api.status)}</td></tr>`).join("")}
        </tbody>
      </table>
    </section>

    <section class="content" id="database">
      <h1 class="sec">10. Database / Data Layer Scope</h1>
      <div class="warn">${esc(PLAN.database.statement)}</div>
      ${PLAN.database.entities.map((entity) => `
        <article class="module">
          <h3>${esc(entity.name)}</h3>
          <p>${esc(entity.purpose)}</p>
          <p><strong>Relationships.</strong> ${esc(entity.relationships)}</p>
          <p><strong>CRUD requirement.</strong> ${esc(entity.crud)}</p>
          <p><strong>Used by.</strong> ${esc(entity.usedBy)} · <strong>Related sprint.</strong> ${esc(entity.sprint)}</p>
          ${entity.fields ? `<h4>Named college data</h4>${list(entity.fields)}` : ""}
        </article>`).join("")}
    </section>

    <section class="content" id="integrations">
      <h1 class="sec">11. Integration Scope</h1>
      <table>
        <thead><tr><th>Integration</th><th>Purpose</th><th>Module</th><th>Development requirement</th><th>Dependency</th><th>Status</th></tr></thead>
        <tbody>
          ${PLAN.integrations.map((row) => `<tr><td>${esc(row.name)}</td><td>${esc(row.purpose)}</td><td>${esc(row.module)}</td><td>${esc(row.requirement)}</td><td>${esc(row.dependency)}</td><td>${badge(row.status)}</td></tr>`).join("")}
        </tbody>
      </table>
    </section>

    <section class="content" id="workflows">
      <h1 class="sec">12. Business Logic &amp; Workflow</h1>
      <h2>Student journey</h2>
      <p>Day 2 studies this journey, together with the general counselling flow and student data collection requirements.</p>
      <div class="flow">${PLAN.studentJourney.map((step, i) => `<span>${esc(step)}</span>${i < PLAN.studentJourney.length - 1 ? "<i>↓</i>" : ""}`).join("")}</div>
      <h3>Alongside the journey</h3>
      ${list(["General counselling flow", "Student data collection requirements"])}
      <h2>Enquiry steps</h2>
      <div class="flow">${PLAN.enquirySteps.map((step, i) => `<span>${esc(step)}</span>${i < PLAN.enquirySteps.length - 1 ? "<i>↓</i>" : ""}`).join("")}</div>
      <p>The enquiry UI also includes validation/error states, and the build includes validation, submission, and an enquiry status foundation.</p>
      <h2>Agreed lead-routing flow</h2>
      <p>Sprint 6 implements this agreed core flow.</p>
      <div class="flow">${PLAN.leadFlow.map((step, i) => `<span>${esc(step)}</span>${i < PLAN.leadFlow.length - 1 ? "<i>↓</i>" : ""}`).join("")}</div>
      <h3>Routing logic retained with the flow</h3>
      ${list(["Best Academy first-priority flow", "Counsellor handling flow", "College assignment flow", "Lead status requirements", "Routing conditions", "Tracking requirements", "Priority logic", "Assignment logic", "Status transition logic", "Routing history", "Lead priority", "College assignment", "Status transitions"])}
      <h2>Business rules completed in Sprint 7</h2>
      ${list(["Qualification/course rules", "College matching rules", "Enquiry rules", "Lead priority", "College assignment", "Status transitions", "Duplicate/invalid data handling"])}
      <p>Recommendation/business-rule implementation is based on finalized requirements.</p>
    </section>

    <section class="content" id="dependencies">
      <h1 class="sec">13. Dependencies &amp; Client Inputs</h1>
      <table>
        <thead><tr><th>Dependency</th><th>Type</th><th>Detail</th><th>Sprint</th><th>Status</th></tr></thead>
        <tbody>
          ${PLAN.dependencies.map((row) => `<tr><td>${esc(row.name)}</td><td>${esc(row.type)}</td><td>${esc(row.detail)}</td><td>${esc(row.sprint)}</td><td>${badge(row.status)}</td></tr>`).join("")}
        </tbody>
      </table>
    </section>

    <section class="content" id="feasibility">
      <h1 class="sec">14. Technical Feasibility / TBC Items</h1>
      <article class="feasibility">
        <p class="eyebrow">${esc(PLAN.feasibility.sprint)}</p>
        <h2>${esc(PLAN.feasibility.title)}</h2>
        ${badge(PLAN.feasibility.status)}
        <h3>Requirement</h3>
        <p>${esc(PLAN.feasibility.requirement)}</p>
        <h3>Why confirmation is required</h3>
        <p>${esc(PLAN.feasibility.why)}</p>
        <h3>Validation required</h3>
        ${list(PLAN.feasibility.validation)}
        <h3>Client statement</h3>
        <blockquote>${esc(PLAN.feasibility.statement)}</blockquote>
        <h3>Implementation</h3>
        <p><strong>${esc(PLAN.feasibility.implementation)}</strong></p>
      </article>
    </section>

    <section class="content" id="deliverables">
      <h1 class="sec">15. Sprint Deliverables</h1>
      <div class="cards">
        ${PLAN.sprints.map((s) => `<article><p>Sprint ${esc(s.code)} · ${esc(s.week)}</p><h3>${esc(s.title)}</h3><p>${esc(s.deliverables[0])}</p></article>`).join("")}
        <article><p>Separate phase</p><h3>QA – 10 Working Days</h3><p>Final Regression + QA Sign-off</p></article>
      </div>
    </section>

    <section class="content" id="flow">
      <h1 class="sec">16. Overall Development Completion Flow</h1>
      <div class="flow">${PLAN.completionFlow.map((step, i) => `<span><small>${esc(step.sprint)}</small>${esc(step.label)}</span>${i < PLAN.completionFlow.length - 1 ? "<i>↓</i>" : ""}`).join("")}</div>
    </section>

    <section class="content" id="summary">
      <h1 class="sec">17. Timeline Summary</h1>
      <table>
        <thead><tr><th>Sprint</th><th>Duration</th><th>Focus</th><th>Major work</th><th>Deliverable</th><th>Status</th></tr></thead>
        <tbody>
          ${PLAN.sprints.map((s) => `<tr><td>${esc(s.week)}<br>Sprint ${esc(s.code)}</td><td>${esc(s.duration)}</td><td>${esc(s.distributionFocus)}</td><td>${esc(s.title)}<br>${esc(s.daysLabel)}</td><td>${esc(s.deliverables[0])}</td><td>${badge(s.status)}</td></tr>`).join("")}
          <tr><td>QA / Testing</td><td>${esc(PLAN.qaDuration)}</td><td>Separate Testing Phase</td><td>Testing activities listed below</td><td>Final Regression + QA Sign-off</td><td>${badge("PLANNED")}</td></tr>
          <tr><td>Overall</td><td>${esc(PLAN.totalDuration)}</td><td colspan="4">40 Working Days development + 10 Working Days testing / QA</td></tr>
        </tbody>
      </table>
      <h2>Development distribution</h2>
      <table>
        <thead><tr><th>Week</th><th>Focus</th><th>Days</th></tr></thead>
        <tbody>
          ${PLAN.sprints.map((s) => `<tr><td>${esc(s.week)}</td><td>${esc(s.distributionFocus)}</td><td>5</td></tr>`).join("")}
          <tr><td>Total Development</td><td></td><td>40 Days</td></tr>
          <tr><td>QA / Testing</td><td>Separate Testing Phase</td><td>10 Days</td></tr>
          <tr><td>Overall</td><td></td><td>50 Working Days</td></tr>
        </tbody>
      </table>
    </section>

    <section class="content" id="notes">
      <h1 class="sec">18. Important Notes</h1>
      ${PLAN.notes.map((note) => `<article class="note-card"><h3>${esc(note.title)}</h3><p>${esc(note.body)}</p></article>`).join("")}
    </section>

    <section class="content" id="handover">
      <h1 class="sec">19. Final Development Handover / Next Phase</h1>
      <p>At the end of the eight development sprints, the expected result is a development-complete build handed to QA.</p>
      <h2>Development complete</h2>
      ${list(PLAN.handover.developmentComplete)}
      <h2>What follows development</h2>
      <div class="flow">${PLAN.handover.flow.map((step, i) => `<span>${esc(step)}</span>${i < PLAN.handover.flow.length - 1 ? "<i>↓</i>" : ""}`).join("")}</div>
      <p>${esc(PLAN.handover.uatNote)}</p>
      <p>${esc(PLAN.handover.releaseNote)}</p>
      <h2>${esc(PLAN.qa.title)}</h2>
      <p>${esc(PLAN.qa.note)} These testing activities are not mixed into the 40 development days.</p>
      <table>
        <thead><tr><th>Days</th><th>Testing activity</th></tr></thead>
        <tbody>
          ${PLAN.qa.rows.map((row) => `<tr><td>${esc(row.days)}</td><td>${esc(row.activity)}</td></tr>`).join("")}
        </tbody>
      </table>
    </section>

    <footer class="doc-foot">
      <span>${esc(PLAN.project)} · ${esc(PLAN.title)}</span>
      <span>${esc(PLAN.date)}</span>
    </footer>`;
}
