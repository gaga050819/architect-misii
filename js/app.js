// Точка входу: завантажує дані, тримає стан гри і перемикає екрани.
import { loadData } from './data.js';
import { randomSeed } from './rng.js';
import { decodeMission, toast } from './ui/dom.js';
import * as briefing from './ui/briefing.js';
import * as builder from './ui/builder.js';
import * as devScreen from './ui/dev.js';
import * as flight from './ui/flight.js';
import * as summary from './ui/summary.js';
import * as colony from './ui/colony.js';
import { renderAbout } from './ui/about.js';
import { setSound } from './ui/sound.js';
import { startDemo } from './ui/demo.js';
import { DEMO_BUILDS, DEMO_SEED } from './demo-script.js';
import { setLang, getLang } from './i18n.js';

const SCREENS = { briefing, builder, dev: devScreen, flight, summary, colony };
const ORDER = ['briefing', 'builder', 'dev', 'flight', 'summary'];

export const app = {
  data: null,
  build: emptyBuild(),
  seed: randomSeed(),
  mission: null,
  dev: null,
  demo: null,
  screen: 'briefing',
  root: document.getElementById('screen'),

  go(screen, { focus = true } = {}) {
    this.screen = screen;
    this.render();
    if (focus) { window.scrollTo(0, 0); this.root.focus({ preventScroll: true }); }
  },
  render() {
    SCREENS[this.screen].render(this.root, this);
    const idx = ORDER.indexOf(this.screen === 'colony' ? 'summary' : this.screen);
    document.querySelectorAll('.stages li').forEach((li) => {
      const i = ORDER.indexOf(li.dataset.stage);
      li.classList.toggle('is-current', i === idx);
      li.classList.toggle('is-done', i < idx);
      if (i === idx) li.setAttribute('aria-current', 'step'); else li.removeAttribute('aria-current');
    });
  },
  newSeed() { this.seed = randomSeed(); },
  reset() { const engineer = this.build.engineer; this.build = { ...emptyBuild(), engineer }; this.newSeed(); this.mission = null; this.dev = null; },
};

export function emptyBuild() {
  return {
    target: null, cls: null, goal: null, rocket: null, platform: null, instruments: [], power: null, antenna: null, extras: [],
    riskClass: 'C', reserve: 25, testing: 'std',
    engineer: false, trajectory: 'direct', propulsion: 'chem', orbit: 'standard', dsn: 'std',
  };
}

async function start() {
  try {
    app.data = await loadData();
  } catch (err) {
    app.root.innerHTML = `<div class="panel"><h2>Не вдалося завантажити дані гри</h2><p>${err.message}</p>
      <p class="muted">Якщо ви відкрили index.html прямо з диска, браузер блокує читання JSON. Запустіть локальний сервер: <code>python -m http.server</code> у папці проєкту і відкрийте http://localhost:8000.</p></div>`;
    return;
  }

  const modeToggle = document.getElementById('mode-toggle');
  const applyMode = (on) => {
    modeToggle.checked = on;
    document.body.classList.toggle('mode-engineer', on);
    document.body.classList.toggle('mode-cadet', !on);
  };
  app.applyMode = applyMode;
  modeToggle.addEventListener('change', () => {
    applyMode(modeToggle.checked);
    app.build.engineer = modeToggle.checked;
    // Режим змінює правила (траєкторії, двигуни, планетарний захист), тому розробку починаємо заново
    if (app.screen === 'briefing' || app.screen === 'builder' || (app.screen === 'dev' && !(app.dev && app.dev.started))) {
      app.dev = null;
      app.render();
    } else {
      toast('Нові правила режиму почнуть діяти з наступної місії');
    }
  });

  const soundToggle = document.getElementById('sound-toggle');
  soundToggle.addEventListener('change', () => setSound(soundToggle.checked));

  const SVG_SUN = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>';
  const SVG_MOON = '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>';
  const themeToggle = document.getElementById('theme-toggle');
  const updateThemeUI = (theme) => {
    if (!themeToggle) return;
    const isDark = theme === 'dark';
    const icon = themeToggle.querySelector('.theme-icon');
    const label = themeToggle.querySelector('.theme-label');
    if (icon) icon.innerHTML = isDark ? SVG_SUN : SVG_MOON;
    if (label) label.textContent = isDark ? 'Світла' : 'Темна';
    themeToggle.setAttribute('title', isDark ? 'Перемкнути на світлу тему' : 'Перемкнути на темну тему');
    themeToggle.setAttribute('aria-label', isDark ? 'Перемкнути на світлу тему' : 'Перемкнути на темну тему');
  };
  const setTheme = (theme, save = false) => {
    document.documentElement.setAttribute('data-theme', theme);
    if (save) {
      try {
        localStorage.setItem('theme', theme);
      } catch {
        void 0;
      }
    }
    updateThemeUI(theme);
  };
  const initialTheme = document.documentElement.getAttribute('data-theme')
    || localStorage.getItem('theme')
    || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  setTheme(initialTheme);
  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const active = document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
      setTheme(active === 'dark' ? 'light' : 'dark', true);
    });
  }
  try {
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    mq.addEventListener('change', (e) => {
      if (!localStorage.getItem('theme')) {
        setTheme(e.matches ? 'dark' : 'light');
      }
    });
  } catch {
    void 0;
  }

  const langToggle = document.getElementById('lang-toggle');
  const applyLang = (l, rerender = true) => {
    setLang(l);
    if (langToggle) langToggle.textContent = l === 'uk' ? 'EN' : 'UA';
    try { localStorage.setItem('lang', l); } catch { void 0; }
    if (rerender) app.render();
  };
  const initialLang = (() => { try { return localStorage.getItem('lang') || 'uk'; } catch { return 'uk'; } })();
  applyLang(initialLang, false);
  if (langToggle) {
    langToggle.addEventListener('click', () => applyLang(getLang() === 'uk' ? 'en' : 'uk'));
  }

  const about = document.getElementById('about');
  document.getElementById('about-btn').addEventListener('click', () => {
    renderAbout(document.getElementById('about-body'), app);
    about.showModal();
  });
  about.addEventListener('click', (e) => { if (e.target === about || e.target.closest('[data-close]')) about.close(); });
  const viewer = document.getElementById('viewer');
  viewer.addEventListener('click', (e) => { if (e.target === viewer || e.target.closest('[data-close]')) viewer.close(); });

  document.getElementById('demo-btn').addEventListener('click', () => startDemo(app));

  const startVoyager = () => {
    app.build = {
      ...emptyBuild(),
      target: 'interstellar',
      cls: 'flagship',
      goal: 'atmosphere',
      rocket: 'falcon_heavy',
      platform: 'orbiter',
      instruments: ['magnetometer', 'ir_spectrometer', 'mass_spectrometer', 'neutron'],
      power: 'rtg_3',
      antenna: 'hga_large',
      extras: ['radiation_vault'],
      riskClass: 'A',
      reserve: 20,
    };
    app.seed = 'VOYAGER';
    applyMode(false);
    app.go('builder');
    toast('Завантажено історичну місію Voyager');
  };
  document.getElementById('voyager-btn')?.addEventListener('click', startVoyager);

  // Демо для презентації: #demo — показ з підписами; #demo1 і #demo2 — готові конструкції для гри вручну.
  const hash = location.hash.slice(1);
  if (hash === 'voyager') {
    startVoyager();
    return;
  }
  if (hash === 'demo') {
    app.go('briefing', { focus: false });
    startDemo(app);
    return;
  }
  if (DEMO_BUILDS[hash]) {
    app.build = { ...emptyBuild(), ...DEMO_BUILDS[hash] };
    app.seed = DEMO_SEED;
    applyMode(false);
    app.go('builder', { focus: false });
    toast(`Демо-місія ${app.seed}`);
    return;
  }

  const m = location.hash.match(/^#m=(.+)$/);
  if (m) {
    const decoded = decodeMission(m[1]);
    if (decoded) {
      app.build = { ...emptyBuild(), ...decoded.build };
      app.seed = decoded.seed || app.seed;
      applyMode(!!app.build.engineer);
      history.replaceState(null, '', location.pathname + location.search);
      app.go('builder', { focus: false });
      toast(`Завантажено місію ${app.seed}`);
      return;
    }
  }
  app.go('briefing', { focus: false });
}

start();
