import Scene from "@/components/Scene";
import Entrance from "@/components/Entrance";
import Reveal from "@/components/Reveal";
import Typing from "@/components/Typing";
import LiveStatus from "@/components/LiveStatus";
import { links } from "@/lib/assets";
import { areaChart, series, sparkline } from "@/lib/charts";

// ---------------------------------------------------------------------------------------------------------------
// small pieces
// ---------------------------------------------------------------------------------------------------------------

const Chevron = () => (
  <svg width="10" height="10" viewBox="0 0 10 10" fill="none" aria-hidden="true" style={{ opacity: 0.8 }}>
    <path d="M2 3.5 l3 3 3-3" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
const Arrow = () => (
  <svg className="arrow" viewBox="0 0 16 16" fill="none" aria-hidden="true">
    <path d="M2 8 h11 M9 4 l4 4 -4 4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
const Icon = ({ children }: { children: React.ReactNode }) => (
  <span className="icon" aria-hidden="true">
    <svg viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round">{children}</svg>
  </span>
);
const I = {
  cross: <><circle cx="12" cy="12" r="6" /><circle cx="12" cy="12" r="2" /><path d="M12 2v4M12 18v4M2 12h4M18 12h4" /></>,
  screen: <><rect x="3" y="5" width="18" height="12" rx="2" /><path d="M8 21h8M12 17v4" /></>,
  trend: <><path d="M3 17l6-6 4 4 8-8" /><path d="M15 7h6v6" /></>,
  brief: <><rect x="3" y="7" width="18" height="13" rx="2" /><path d="M9 7V5a2 2 0 012-2h2a2 2 0 012 2v2M3 13h18" /></>,
  mega: <><path d="M4 10v4l12 5V5L4 10z" /><path d="M7 15l1 5h3l-1-4" /></>,
  doc: <><path d="M6 3h8l4 4v14H6z" /><path d="M14 3v4h4M9 12h6M9 16h6" /></>,
  code: <><path d="M9 8l-5 4 5 4M15 8l5 4-5 4" /></>,
};
const Mini = ({ d }: { d: string }) => (
  <svg width="15" height="15" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round" style={{ opacity: 0.8 }} aria-hidden="true">
    <path d={d} />
  </svg>
);

const BID = `$ devpilot check
[pass] repository created
[pass] commit message has a summary line
[pass] branch fix/typo exists
[fail] conflict markers left in app.py

Fix the file, then run the check again.`;

// ---------------------------------------------------------------------------------------------------------------
// the dashboard preview (sample data, drawn as SVG)
// ---------------------------------------------------------------------------------------------------------------

function Dashboard() {
  const kpis = [
    { label: "Checks passed", value: "5/5", chip: "+3", color: "#9b8cff", s: series(14, 3, 20, 7, 10), up: true },
    { label: "Labs completed", value: "1", chip: "+1", color: "#ff8fd8", s: series(14, 7, 18, 6, 9), up: true },
    { label: "Streak", value: "1 wk", chip: "new", color: "#7fd6ff", s: series(14, 11, 22, 6, -6), up: false },
    { label: "Skills practised", value: "3", chip: "+2", color: "#7cf0bd", s: series(14, 5, 12, 4, 14), up: true },
  ];
  const a = series(30, 2, 90, 26, 60), b = series(30, 9, 70, 22, 30);
  const ch = areaChart(a, b);
  const bars = [
    ["Python", 38, "#9b8cff"], ["Git", 27, "#7fd6ff"], ["Testing", 19, "#ff8fd8"], ["Debugging", 10, "#ffc27a"], ["Code review", 6, "#7cf0bd"],
  ] as const;
  const rows = [
    ["Hello, Python", "Beginner", "45 min", "100%", "Practice complete", true],
    ["Your first open-source contribution", "Beginner", "2.5 h", "50%", "In progress", true],
    ["Git: your first commit", "Beginner", "30 min", "n/a", "Planned", false],
  ] as const;
  return (
    <div className="dash reveal" id="dash" aria-label="A preview of the DevPilot app with sample data">
      <div className="dash-top">
        <span className="mini-logo"><i className="orb orb-s" />DevPilot</span>
        <span className="crumb">Paths  /  <b>Git and pull requests</b></span>
        <span className="grow" />
        <span className="search">
          <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" aria-hidden="true"><circle cx="7" cy="7" r="4.5" /><path d="M10.5 10.5L14 14" /></svg>
          Search labs and pages <kbd>⌘K</kbd>
        </span>
        <span className="chip">Sample data</span>
        <span className="avatar">AR</span>
      </div>
      <div className="dash-body">
        <aside className="side">
          <div className="grp">WORKSPACE</div>
          <div className="item active"><Mini d="M2 2h5v5H2zM9 2h5v3H9zM9 7h5v7H9zM2 9h5v5H2z" />Dashboard</div>
          <div className="item"><Mini d="M8 2a6 6 0 100 12A6 6 0 008 2zM10.5 5.5L9 9 5.5 10.5 7 7z" />Catalog</div>
          <div className="item"><Mini d="M3 3v4a3 3 0 003 3h4M13 13V9" />Paths <span className="n">1</span></div>
          <div className="item"><Mini d="M8 2l1.8 3.7 4 .6-2.9 2.8.7 4L8 11.2 4.4 13l.7-4L2.2 6.3l4-.6z" />Credentials</div>
          <div className="item"><Mini d="M2 4h5l1 1.5h6V13H2z" />Workspaces</div>
          <div className="grp g2">LIBRARY</div>
          <div className="item"><Mini d="M3 3h10v10H3z" />Labs <span className="n">2</span></div>
          <div className="item"><Mini d="M2 8l4 4 8-8" />Roadmaps</div>
          <div className="item"><Mini d="M3 3h10v7H8l-3 3v-3H3z" />Interview practice</div>
          <div className="item"><Mini d="M8 2v12M2 8h12" />Coach</div>
        </aside>
        <div className="main">
          <div className="main-head">
            <h4>Your week</h4>
            <span className="chip up">▲ 5 checks this week</span>
            <span className="grow" />
            <span className="seg"><i>7D</i><i className="on">30D</i><i>90D</i></span>
            <span className="smallbtn">+ New path</span>
          </div>
          <div className="kpis">
            {kpis.map((k) => {
              const sp = sparkline(k.s);
              return (
                <div className="kpi" key={k.label}>
                  <div className="kl">{k.label}</div>
                  <div className="kv"><span>{k.value}</span><span className={`chip ${k.up ? "up" : ""}`}>{k.chip}</span></div>
                  <svg viewBox="0 0 200 30" preserveAspectRatio="none" className="spark" aria-hidden="true">
                    <defs><linearGradient id={`sg-${k.label.replace(/\W+/g, "-")}`} x1="0" x2="0" y1="0" y2="1"><stop offset="0" stopColor={k.color} stopOpacity=".35" /><stop offset="1" stopColor={k.color} stopOpacity="0" /></linearGradient></defs>
                    <path d={sp.area} fill={`url(#sg-${k.label.replace(/\W+/g, "-")})`} className="fillin" />
                    <path d={sp.line} fill="none" stroke={k.color} strokeWidth="1.6" vectorEffect="non-scaling-stroke" pathLength={1} className="draw" />
                  </svg>
                </div>
              );
            })}
          </div>
          <div className="charts">
            <div className="pane">
              <div className="ph">Checks passed per day <span className="legend"><i style={{ background: "#9b8cff" }} />Checks <i style={{ background: "#ff8fd8" }} />Labs opened</span></div>
              <svg viewBox="0 0 600 190" preserveAspectRatio="none" className="area" aria-hidden="true">
                {[0, 1, 2, 3, 4].map((i) => <line key={i} x1="0" x2="600" y1={12 + i * 41.5} y2={12 + i * 41.5} stroke="rgba(190,170,255,.08)" />)}
                <defs>
                  <linearGradient id="ga" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stopColor="#9b8cff" stopOpacity=".42" /><stop offset="1" stopColor="#9b8cff" stopOpacity="0" /></linearGradient>
                  <linearGradient id="gb" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stopColor="#ff8fd8" stopOpacity=".22" /><stop offset="1" stopColor="#ff8fd8" stopOpacity="0" /></linearGradient>
                </defs>
                <path d={ch.aa} fill="url(#ga)" className="fillin" />
                <path d={ch.ab} fill="url(#gb)" className="fillin" />
                <path d={ch.la} fill="none" stroke="#9b8cff" strokeWidth="2" vectorEffect="non-scaling-stroke" pathLength={1} className="draw" />
                <path d={ch.lb} fill="none" stroke="#ff8fd8" strokeWidth="1.6" vectorEffect="non-scaling-stroke" pathLength={1} className="draw d2" />
                <g className="fillin">
                  <line x1={ch.marker[0]} x2={ch.marker[0]} y1="10" y2="178" stroke="rgba(220,210,255,.25)" strokeDasharray="3 4" />
                  <circle cx={ch.marker[0]} cy={ch.marker[1]} r="4.5" fill="#1a1150" stroke="#b9adff" strokeWidth="2" />
                </g>
              </svg>
            </div>
            <div className="pane">
              <div className="ph">Skills practised</div>
              <div className="bars">
                {bars.map(([name, v, c]) => (
                  <div key={name}>
                    <div className="bl"><span>{name}</span><span className="mono">{v}%</span></div>
                    <div className="track"><div className="barfill" style={{ ["--w" as string]: `${(v / 38) * 100}%`, background: `linear-gradient(90deg, ${c}, ${c}aa)` }} /></div>
                  </div>
                ))}
              </div>
            </div>
          </div>
          <div className="table">
            <div className="tr th"><span>Lab</span><span>Level</span><span>Time</span><span>Progress</span><span>Status</span></div>
            {rows.map(([name, level, time, prog, status, live]) => (
              <div className="tr" key={name}>
                <b>{name}</b><span>{level}</span><span className="mono">{time}</span><span className="mono">{prog}</span>
                <span><span className={`chip ${live ? "live" : ""}`}>{status}</span></span>
              </div>
            ))}
          </div>
          <p className="sample-note">Sample data, shown for illustration.</p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------------------------------------------
// page
// ---------------------------------------------------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <Scene />
      <Entrance />
      <Reveal />

      <nav className="nav" id="nav" data-in="nav" aria-label="Main">
        <a href="#top" className="logo"><i className="orb" />DevPilot</a>
        <div className="menu">
          <a href="#packs">Product <Chevron /></a>
          <a href="#studio">Learn <Chevron /></a>
          <a href="#end">Resources <Chevron /></a>
          <a href="#uses">Who it is for</a>
        </div>
        <div className="right">
          <a href={links.docs} className="login">Docs</a>
          <a href={links.github} className="pill glass">GitHub</a>
          <a href={links.releases} className="pill dark">Get DevPilot</a>
        </div>
      </nav>

      <main id="top">
        {/* ------------------------------------------------------------------------------------------ hero */}
        <section id="hero" className="hero">
          <h1 className="h-hero">
            <span className="mask"><span data-in="l1">Introducing</span></span>
            <span className="mask"><span data-in="l2">DevPilot</span></span>
          </h1>
          <p className="sub" data-in="sub">Guided labs &amp; AI learning paths</p>
          <div className="hero-btns" data-in="btns">
            <a className="btn fill" href={links.download}>Download for Linux</a>
            <a className="btn ghost" href="#studio">See how it works</a>
          </div>
          <a className="scrollcard" href="#studio" data-in="card" aria-label="Scroll down">
            <span>Scroll down<br />&amp; discover</span>
            <svg className="down" viewBox="0 0 22 22" fill="none" aria-hidden="true">
              <path d="M11 3 v15 M5 12 l6 6 6-6" stroke="#fff" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </a>
        </section>

        {/* ------------------------------------------------------------------------------------------ studio */}
        <section id="studio" className="studio">
          <h2 className="h2 reveal" style={{ maxWidth: "calc(var(--u) * 1240)", margin: "calc(var(--u) * 22) auto 0" }}>
            The practical way to learn <span className="acc">real engineering tools</span><br />with guided labs and an AI mentor.
          </h2>
          <p className="lede reveal" style={{ maxWidth: "calc(var(--u) * 640)", margin: "calc(var(--u) * 22) auto 0" }}>
            Tell DevPilot what you want to learn. It builds the path, finds the videos, writes the labs and checks your work, all on your own computer.
          </p>
          <div className="btnrow reveal">
            <a className="btn fill" href={links.download}>Download for Linux</a>
            <a className="btn ghost" href={links.github}>View on GitHub</a>
          </div>
          <div className="stats reveal">
            <div><strong>9</strong><span>languages for the tutor<br />and the coach</span></div>
            <div><strong>80%</strong><span>of each video must be<br />watched, and it is measured</span></div>
            <div><strong>100%</strong><span>of your lab code runs<br />on your own computer</span></div>
            <div><strong>0</strong><span>finished answers from the<br />tutor: hints only</span></div>
          </div>
          <Dashboard />
        </section>

        {/* ------------------------------------------------------------------------------------------ how it works */}
        <section id="packs" className="packs">
          <div className="split">
            <div className="reveal">
              <h2 className="h2" style={{ marginTop: "calc(var(--u) * 22)", maxWidth: "calc(var(--u) * 700)" }}>
                Plan it, watch it, practise it, check it, <span className="acc">prove <em className="serif">it.</em></span>
              </h2>
              <p className="lede" style={{ maxWidth: "calc(var(--u) * 560)", marginTop: "calc(var(--u) * 22)" }}>
                Start from a goal or a job description. DevPilot plans the steps, and each one opens only when you have finished the one before it.
              </p>
              <div className="btnrow left">
                <a className="btn white" href={links.docs}>Read the docs</a>
                <a className="btn dk" href={links.download}>Download</a>
              </div>
            </div>
            <div className="reveal codeblock" aria-hidden="true">
              <div className="ch"><span>terminal</span><span>Lab check</span></div>
              <Typing text={BID} label="A lab check running in the terminal" />
              <div className="cf"><span>step 4 of 6</span><span className="live-dot">checking</span></div>
            </div>
          </div>

          <div className="cards">
            <article className="card glass lead reveal" style={{ transitionDelay: "0s" }}>
              <div className="row"><span className="idx">01</span><Icon>{I.cross}</Icon></div>
              <div className="eyebrow">AI-PLANNED PATHS</div>
              <h3>Learn Anything, Step by Step</h3>
              <p>Name a goal or paste a job description. Gemini plans the steps and fills in each one when you reach it.</p>
              <div className="meta"><div><small>Steps per path</small><b>3–8</b></div><a className="tl" href={links.docs}>Build a path <Arrow /></a></div>
            </article>
            <article className="card glass reveal" style={{ transitionDelay: ".08s" }}>
              <div className="row"><span className="idx">02</span><Icon>{I.screen}</Icon></div>
              <div className="eyebrow">REAL LABS</div>
              <h3>Practise in Your Own VS Code</h3>
              <p>Short projects with starter files. Checks run on your computer and turn green one step at a time.</p>
              <div className="meta"><div><small>Where code runs</small><b>100%</b></div><a className="tl" href={links.docs}>See the labs <Arrow /></a></div>
            </article>
            <article className="card glass reveal" style={{ transitionDelay: ".16s" }}>
              <div className="row"><span className="idx">03</span><Icon>{I.trend}</Icon></div>
              <div className="eyebrow">PROOF</div>
              <h3>Show What You Can Do</h3>
              <p>Claim a credential from a finished lab. It says plainly how it was checked, never more.</p>
              <div className="meta"><div><small>Credential tiers</small><b>2</b></div><a className="tl" href={links.docs}>How it works <Arrow /></a></div>
            </article>
          </div>

          <ol className="steps reveal">
            <li><span><b>Say your goal</b> Type a topic, or paste the job you want.</span></li>
            <li><span><b>Learn, watch, check</b> An explanation, videos, a quick check, then the lab.</span></li>
            <li><span><b>Finish to unlock</b> The next step opens when this one is done.</span></li>
          </ol>
        </section>

        {/* ------------------------------------------------------------------------------------------ who it is for */}
        <section id="uses" className="uses">
          <div className="uses-head">
            <h2 className="h2 reveal">Built for everyone<br />who <em className="serif">learns</em> tools.</h2>
            <p className="lede reveal">One app, four ways in. Start with what you need, and nothing you don&apos;t.</p>
          </div>
          <div className="stairs">
            {[
              ["Engineering Student", I.brief, "Your course covers the theory. Practise Git, testing and debugging on real projects.", ["Guided labs", "Hints in 9 languages"]],
              ["Career Switcher", I.mega, "Paste the job you want. Get a path of steps that gets you ready for it.", ["Job-description paths", "Interview practice"]],
              ["Open-Source Beginner", I.doc, "Fix real bugs on real branches, write the pull request, answer the review.", ["Git workflow", "Code review coach"]],
              ["Mentor or College", I.code, "See where a class is stuck, and give everyone the same path.", ["Cohorts (planned)", "Mentor view (planned)"]],
            ].map(([title, icon, body, chips], i) => (
              <article className={`role glass reveal r${i + 1}`} key={title as string} style={{ transitionDelay: `${i * 0.06}s` }}>
                <div className="row"><span className="tag">USE CASE</span><Icon>{icon as React.ReactNode}</Icon></div>
                <h3>{title as string}</h3>
                <p>{body as string}</p>
                <div className="chips">{(chips as string[]).map((c) => <span className="chip" key={c}>{c}</span>)}</div>
                <a className="tl" href={links.releases}>Explore now <Arrow /></a>
              </article>
            ))}
          </div>
        </section>

        {/* ------------------------------------------------------------------------------------------ call to action + footer */}
        <section id="end" className="end">
          <div className="cta glass reveal">
            <h2 className="h-cta">Start Learning<br /><em className="serif">Real Tools</em> Now!</h2>
            <p className="lede" style={{ maxWidth: "calc(var(--u) * 540)", margin: "calc(var(--u) * 20) auto 0" }}>
              Download DevPilot and your first guided lab can be open in VS Code within minutes.
            </p>
            <div className="btnrow">
              <a className="btn fill" href={links.download}>Download for Linux</a>
              <a className="btn ghost" href={links.github}>View on GitHub</a>
            </div>
            <p className="note">Labs run on your computer  ·  Hints, not answers</p>
          </div>

          <footer className="foot">
            <div className="fgrid">
              <div>
                <a href="#top" className="logo flogo"><i className="orb" />DevPilot</a>
                <p className="fbrand">The guided way to learn practical engineering tools, from first goal to proven skill.</p>
                <LiveStatus />
              </div>
              <div><h5>PRODUCT</h5><a href={links.docs}>Learning paths</a><a href={links.docs}>Labs</a><a href={links.docs}>Coach</a><a href={links.docs}>Credentials</a></div>
              <div><h5>WHO IT IS FOR</h5><a href="#uses">Students</a><a href="#uses">Career switchers</a><a href="#uses">Open-source beginners</a><a href="#uses">Mentors</a></div>
              <div><h5>PLATFORMS</h5><a href={links.download}>Linux</a><a href={links.releases}>Windows (soon)</a><a href={links.releases}>macOS (soon)</a><a href={links.docs}>VS Code</a></div>
              <div><h5>RESOURCES</h5><a href={links.github}>GitHub</a><a href={links.docs}>Documentation</a><a href={`${links.api}/health`}>Service status</a><a href={links.issues}>Contact</a></div>
            </div>
            <div className="legal">
              <span>©2026 DevPilot</span>
              <span className="ll"><a href="#">Privacy</a><a href="#">Terms</a><a href={links.docs}>Security</a></span>
            </div>
            <div className="wordmark" aria-hidden="true">DevPilot</div>
          </footer>
        </section>
      </main>
    </>
  );
}
