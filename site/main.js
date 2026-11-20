// Renders the ecosystem graph with a mermaid theme that follows the
// colour scheme, and re-renders it when the scheme changes.
(function () {
  var el = document.getElementById("ecosystem-graph");
  if (!el || !window.mermaid) return;
  var source = el.textContent;
  var dark = window.matchMedia("(prefers-color-scheme: dark)");

  function render() {
    var isDark = dark.matches;
    mermaid.initialize({
      startOnLoad: false,
      securityLevel: "loose",   // needed for the `click ... href` links
      theme: "base",
      themeVariables: isDark ? {
        darkMode: true,
        background: "#282f2f",
        primaryColor: "#282f2f",
        primaryBorderColor: "#4b5657",
        primaryTextColor: "#e6e9ea",
        lineColor: "#7f8c8d",
        fontFamily: "Lato, Helvetica Neue, Arial, sans-serif"
      } : {
        background: "#f5f7fa",
        primaryColor: "#f5f7fa",
        primaryBorderColor: "#b8c3cf",
        primaryTextColor: "#222222",
        lineColor: "#8a96a3",
        fontFamily: "Lato, Helvetica Neue, Arial, sans-serif"
      },
      flowchart: { curve: "basis", nodeSpacing: 28, rankSpacing: 48, padding: 10 }
    });
    el.removeAttribute("data-processed");
    el.textContent = source;
    return mermaid.run({ nodes: [el] });
  }

  render();
  if (dark.addEventListener) dark.addEventListener("change", render);
})();

// Copies a publication's BibTeX entry and briefly shows a check mark.
document.addEventListener("click", function (ev) {
  var btn = ev.target.closest(".copy-btn");
  if (!btn || !navigator.clipboard) return;
  var pre = btn.parentNode.querySelector("pre");
  navigator.clipboard.writeText(pre.textContent).then(function () {
    btn.dataset.state = "copied";
    btn.setAttribute("aria-label", "BibTeX copied");
    clearTimeout(btn._reset);
    btn._reset = setTimeout(function () {
      delete btn.dataset.state;
      btn.setAttribute("aria-label", "Copy BibTeX");
    }, 1600);
  });
});

// Draws the title banner's eye and spirals (style.css lays the banner out), then fits its 1701x925 design stage to
// the banner's width.
document.querySelectorAll(".iris-banner").forEach(function (banner, idx) {
  var svg = banner.querySelector(".iris-art");
  var NS = "http://www.w3.org/2000/svg";
  var cx = 560, cy = 470, P = "b" + idx + "-";   // the pupil: the centre of the spirals; ids per banner
  var seed = 11;
  function rnd() { seed = (seed * 16807) % 2147483647; return seed / 2147483647; }
  function el(name, attrs, parent) {
    var e = document.createElementNS(NS, name);
    for (var k in attrs) e.setAttribute(k, attrs[k]);
    (parent || svg).appendChild(e); return e;
  }
  function path(f, t0, t1, n) {                  // a polar curve r(t) about the pupil, as one smooth path
    var p = [];
    for (var i = 0; i <= n; i++) { var t = t0 + (t1 - t0) * i / n, r = f(t); p.push((cx + r * Math.cos(t)).toFixed(1) + "," + (cy + r * Math.sin(t)).toFixed(1)); }
    return "M" + p.join(" L");
  }
  var defs = el("defs", {});
  var g1 = el("radialGradient", { id: P + "sclera", cx: "50%", cy: "45%", r: "60%" }, defs);
  el("stop", { offset: "0%", "stop-color": "#f3ece4" }, g1); el("stop", { offset: "100%", "stop-color": "#b9a79a" }, g1);
  var g2 = el("radialGradient", { id: P + "iris", cx: "50%", cy: "50%", r: "50%" }, defs);
  el("stop", { offset: "0%", "stop-color": "#e0482c" }, g2); el("stop", { offset: "55%", "stop-color": "#9a1d16" }, g2);
  el("stop", { offset: "100%", "stop-color": "#3a0808" }, g2);
  var almond = "M " + (cx - 360) + " " + cy + " Q " + cx + " " + (cy - 250) + " " + (cx + 360) + " " + cy +
               " Q " + cx + " " + (cy + 250) + " " + (cx - 360) + " " + cy + " Z";
  var clip = el("clipPath", { id: P + "eye" }, defs); el("path", { d: almond }, clip);

  // Whitney's spirograph, after the titles: rosettes turning about the pupil, and one spiral unwinding from it.
  var spirals = el("g", { class: "spirals", fill: "none", "stroke-linecap": "round" });
  [ { R: 300, k: 7,  m: 0.42, rot: 0.0,  c: "#ff5a3c", w: 1.6, o: 0.55 },
    { R: 380, k: 9,  m: 0.30, rot: 0.17, c: "#ffb08f", w: 1.1, o: 0.35 },
    { R: 470, k: 11, m: 0.22, rot: 0.33, c: "#d71f2a", w: 1.3, o: 0.45 },
    { R: 600, k: 13, m: 0.16, rot: 0.08, c: "#ff8a5c", w: 1.0, o: 0.25 } ].forEach(function (q) {
    el("path", { d: path(function (t) { return q.R * (1 - q.m + q.m * Math.cos(q.k * (t + q.rot))); }, 0, 2 * Math.PI, 1600),
                 stroke: q.c, "stroke-width": q.w, opacity: q.o }, spirals);
  });
  el("path", { d: path(function (t) { return 150 + 34 * t; }, 0, 9 * 2 * Math.PI, 3000),   // the unwinding spiral
               stroke: "#ff6a46", "stroke-width": 1.4, opacity: 0.35 }, spirals);

  // The eye: an almond of sclera, an iris of fibres, a pupil formed by seven aperture blades.
  el("path", { d: almond, fill: "url(#" + P + "sclera)", stroke: "#1a0607", "stroke-width": 6 });
  var eye = el("g", { "clip-path": "url(#" + P + "eye)" });
  el("circle", { cx: cx, cy: cy, r: 150, fill: "url(#" + P + "iris)" }, eye);
  for (var i = 0; i < 220; i++) {
    var a = (i / 220) * 2 * Math.PI + rnd() * 0.02, r0 = 62 + rnd() * 12, r1 = 118 + rnd() * 30;
    el("line", { x1: cx + r0 * Math.cos(a), y1: cy + r0 * Math.sin(a), x2: cx + r1 * Math.cos(a), y2: cy + r1 * Math.sin(a),
                 stroke: rnd() < 0.5 ? "#ff7a52" : "#5c0c0c", "stroke-width": 1 + rnd() * 1.2, opacity: 0.55 }, eye);
  }
  el("circle", { cx: cx, cy: cy, r: 150, fill: "none", stroke: "#240405", "stroke-width": 7 }, eye);
  var N = 7, rp = 58, rot = 0.21;
  for (var bl = 0; bl < N; bl++) {
    var a0 = rot + (bl / N) * 2 * Math.PI, a1 = rot + ((bl + 1) / N) * 2 * Math.PI;
    var ox = cx + 135 * Math.cos(a0 + 0.55), oy = cy + 135 * Math.sin(a0 + 0.55);
    el("path", { d: "M " + (cx + rp * Math.cos(a0)) + " " + (cy + rp * Math.sin(a0)) + " L " + (cx + rp * Math.cos(a1)) + " " +
                     (cy + rp * Math.sin(a1)) + " Q " + (cx + 150 * Math.cos(a1 + 0.2)) + " " + (cy + 150 * Math.sin(a1 + 0.2)) + " " + ox + " " + oy + " Z",
                 fill: bl % 2 ? "#1c0506" : "#2a0708", stroke: "#ff6a46", "stroke-width": 1.2, "stroke-opacity": 0.6 }, eye);
  }
  var hept = [];
  for (var h = 0; h < N; h++) { var ah = rot + (h / N) * 2 * Math.PI; hept.push((cx + rp * Math.cos(ah)) + "," + (cy + rp * Math.sin(ah))); }
  el("polygon", { points: hept.join(" "), fill: "#050101" }, eye);
  el("circle", { cx: cx - 52, cy: cy - 58, r: 17, fill: "#fff6ef", opacity: 0.9 }, eye);
  el("circle", { cx: cx + 40, cy: cy + 44, r: 6, fill: "#fff6ef", opacity: 0.6 }, eye);

  // Out-of-focus highlights: seven-sided discs, the aperture's own shape.
  [[1290, 700, 34, 0.18], [1560, 120, 24, 0.14], [930, 790, 18, 0.12], [1630, 800, 40, 0.10], [170, 140, 28, 0.12]].forEach(function (q) {
    var pts = [];
    for (var k = 0; k < 7; k++) { var aa = rot + (k / 7) * 2 * Math.PI; pts.push((q[0] + q[2] * Math.cos(aa)) + "," + (q[1] + q[2] * Math.sin(aa))); }
    el("polygon", { points: pts.join(" "), fill: "#ff8a5c", opacity: q[3] });
  });

  function fit() { banner.style.setProperty("--k", banner.clientWidth / 1701); }
  if (window.ResizeObserver) new ResizeObserver(fit).observe(banner);
  fit();
});
