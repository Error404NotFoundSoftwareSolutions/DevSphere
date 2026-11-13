import Scene from "@/components/Scene";
import Entrance from "@/components/Entrance";
import Reveal from "@/components/Reveal";
import Typing from "@/components/Typing";
import LiveStatus from "@/components/LiveStatus";
import { links } from "@/lib/assets";
import AppShowcase from "@/components/AppShowcase";
import DownloadLink from "@/components/DownloadLink";

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
            <DownloadLink className="btn fill" />
            <a className="btn ghost" href="#studio">See how it works</a>
          </div>
          <p className="platforms" data-in="btns">
            Also for: <a href={links.downloadWindows}>Windows</a> <i>·</i> <a href={links.download}>Linux</a> <i>·</i> <span>macOS soon</span>
          </p>
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
            <DownloadLink className="btn fill" />
            <a className="btn ghost" href={links.github}>View on GitHub</a>
          </div>
          <div className="stats reveal">
            <div><strong>9</strong><span>languages for the tutor<br />and the coach</span></div>
            <div><strong>80%</strong><span>of each video must be<br />watched, and it is measured</span></div>
            <div><strong>100%</strong><span>of your lab code runs<br />on your own computer</span></div>
            <div><strong>0</strong><span>finished answers from the<br />tutor: hints only</span></div>
          </div>
          <AppShowcase />
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
                <DownloadLink className="btn dk" plain />
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
              <DownloadLink className="btn fill" />
              <a className="btn ghost" href={links.github}>View on GitHub</a>
            </div>
            <p className="platforms mid">
              Download for: <a href={links.downloadWindows}>Windows</a> <i>·</i> <a href={links.download}>Linux</a> <i>·</i> <span>macOS soon</span>
            </p>
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
              <div><h5>PLATFORMS</h5><a href={links.download}>Linux</a><a href={links.downloadWindows}>Windows</a><a href={links.releases}>macOS (soon)</a><a href={links.docs}>VS Code</a></div>
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
