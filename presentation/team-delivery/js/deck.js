(function () {
  const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  const slides = Array.from(document.querySelectorAll(".slide"));
  const titleEl = document.getElementById("foot-title");
  const pageEl = document.getElementById("foot-page");
  const segments = document.getElementById("segments");
  const toc = document.getElementById("toc");
  const tocGrid = document.getElementById("toc-grid");
  let index = 0;

  function parseDMY(value) {
    const [day, month, year] = value.split("-").map(Number);
    return Date.UTC(year, month - 1, day);
  }

  function layoutGantt(gantt) {
    const min = parseDMY(gantt.dataset.min);
    const max = parseDMY(gantt.dataset.max);
    const span = max - min;
    const pct = (time) => ((time - min) / span) * 100;

    gantt.querySelectorAll(".tick, .vline").forEach((node) => node.remove());
    const axis = gantt.querySelector(".axis");
    const start = new Date(min);
    let year = start.getUTCFullYear();
    let month = start.getUTCMonth();
    const ticks = [];

    while (Date.UTC(year, month, 1) <= max) {
      const time = Date.UTC(year, month, 1);
      if (time >= min && time <= max) ticks.push({ time, label: MONTHS[month] });
      month += 1;
      if (month > 11) {
        month = 0;
        year += 1;
      }
    }

    ticks.forEach((tick) => {
      const position = pct(tick.time);
      const label = document.createElement("span");
      label.className = "tick";
      label.style.left = position + "%";
      label.textContent = tick.label;
      if (position < 3) label.style.transform = "translateX(0)";
      else if (position > 97) label.style.transform = "translateX(-100%)";
      else label.style.transform = "translateX(-50%)";
      axis.appendChild(label);

      gantt.querySelectorAll(".plot").forEach((plot) => {
        const line = document.createElement("i");
        line.className = "vline";
        line.style.left = position + "%";
        plot.appendChild(line);
      });
    });

    gantt.querySelectorAll(".lane[data-start]").forEach((lane) => {
      const startDate = parseDMY(lane.dataset.start);
      const endDate = parseDMY(lane.dataset.end);
      const plan = lane.querySelector(".bar.plan");
      if (plan) {
        plan.style.left = pct(startDate) + "%";
        plan.style.width = Math.max(pct(endDate) - pct(startDate), 0.35) + "%";
      }

      if (lane.dataset.done) {
        const done = parseDMY(lane.dataset.done);
        const mark = lane.querySelector(".mark");
        if (mark) mark.style.left = pct(done) + "%";
        if (done > endDate) {
          const over = lane.querySelector(".bar.over");
          if (over) {
            over.style.left = pct(endDate) + "%";
            over.style.width = Math.max(pct(done) - pct(endDate), 0.35) + "%";
          }
        }
        if (done < endDate) {
          const solid = lane.querySelector(".bar.solid");
          if (solid) {
            solid.style.left = pct(startDate) + "%";
            solid.style.width = Math.max(pct(done) - pct(startDate), 0.35) + "%";
          }
        }
      }

      if (lane.dataset.mile) {
        const mile = lane.querySelector(".mile");
        if (mile) mile.style.left = pct(parseDMY(lane.dataset.mile)) + "%";
      }
    });
  }

  function layoutAll() {
    document.querySelectorAll(".gantt").forEach(layoutGantt);
  }

  function fit() {
    const scale = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
    document.documentElement.style.setProperty("--scale", String(scale));
  }

  function show(next) {
    index = Math.max(0, Math.min(slides.length - 1, next));
    slides.forEach((slide, slideIndex) => {
      const on = slideIndex === index;
      slide.classList.toggle("active", on);
      slide.toggleAttribute("inert", !on);
      slide.setAttribute("aria-hidden", on ? "false" : "true");
    });
    const current = slides[index];
    titleEl.textContent = current.dataset.title;
    pageEl.textContent = String(index + 1).padStart(2, "0") + " / " + String(slides.length).padStart(2, "0");
    segments.querySelectorAll(".seg").forEach((segment, segmentIndex) => {
      segment.classList.toggle("on", segmentIndex === index);
      segment.classList.toggle("done", segmentIndex < index);
    });
    tocGrid.querySelectorAll("button").forEach((button, buttonIndex) => {
      button.classList.toggle("active", buttonIndex === index);
    });
    const hash = "#" + (index + 1);
    if (location.hash !== hash) history.replaceState(null, "", hash);
  }

  slides.forEach((slide, slideIndex) => {
    const segment = document.createElement("button");
    segment.type = "button";
    segment.className = "seg";
    segment.setAttribute("aria-label", "Go to slide " + (slideIndex + 1) + ": " + slide.dataset.title);
    segment.addEventListener("click", () => show(slideIndex));
    segments.appendChild(segment);

    const jump = document.createElement("button");
    jump.type = "button";
    jump.innerHTML = "<b>" + String(slideIndex + 1).padStart(2, "0") + "</b><span>" + slide.dataset.title + "</span>";
    jump.addEventListener("click", () => {
      toc.classList.remove("open");
      show(slideIndex);
    });
    tocGrid.appendChild(jump);
  });

  document.getElementById("prev").addEventListener("click", () => show(index - 1));
  document.getElementById("next").addEventListener("click", () => show(index + 1));
  document.getElementById("menu").addEventListener("click", () => toc.classList.toggle("open"));
  document.getElementById("toc-close").addEventListener("click", () => toc.classList.remove("open"));

  document.addEventListener("keydown", (event) => {
    const key = event.key;
    if (["ArrowRight", "ArrowDown", "PageDown", " "].includes(key)) {
      event.preventDefault();
      show(index + 1);
    } else if (["ArrowLeft", "ArrowUp", "PageUp"].includes(key)) {
      event.preventDefault();
      show(index - 1);
    } else if (key === "Home") {
      show(0);
    } else if (key === "End") {
      show(slides.length - 1);
    } else if (key === "Escape") {
      toc.classList.remove("open");
    } else if (key.toLowerCase() === "m" || key.toLowerCase() === "c") {
      toc.classList.toggle("open");
    }
  });

  let startX = null;
  const deck = document.querySelector(".deck");
  deck.addEventListener("pointerdown", (event) => {
    if (event.target.closest("button, a")) return;
    startX = event.clientX;
  });
  deck.addEventListener("pointerup", (event) => {
    if (startX == null) return;
    const delta = event.clientX - startX;
    if (Math.abs(delta) > 70) show(index + (delta < 0 ? 1 : -1));
    startX = null;
  });

  fit();
  layoutAll();
  const initial = Number((location.hash || "").replace("#", ""));
  show(initial >= 1 && initial <= slides.length ? initial - 1 : 0);
  window.addEventListener("resize", () => {
    fit();
    layoutAll();
  });
})();
