const resourceName = (() => {
  try { return GetParentResourceName(); } catch (_) { return 'nova-vehicleinteract'; }
})();

const app = document.getElementById('app');
const popover = document.getElementById('popover');
const popoverTitle = document.getElementById('popover-title');
const popoverBody = document.getElementById('popover-body');
const toolsEl = document.getElementById('tools');

const emptyState = { seats: [], doors: [], windows: [], plate: '', vehicleName: '' };
let state = { ...emptyState };
let ui = {};
let openTool = null;

// Material Design Icons, Apache-2.0. https://pictogrammers.com/library/mdi/
const ICONS = {
  engine: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M8 10h8v8h-5l-2-2H7v-5m0-7v2h3v2H7l-2 2v3H3v-3H1v8h2v-3h2v3h3l2 2h8v-4h2v3h3V9h-3v3h-2V8h-6V6h3V4z"/></svg>',
  seats: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M7 18S4 10 4 6s2-4 2-4h1s1 0 1 1s-1 1-1 3s3 4 3 7s-3 5-3 5m5-1c-1 0-4 2.5-4 2.5c-.3.2-.2.5 0 .8c0 0 1 1.8 3 1.8h6c1.1 0 2-.9 2-2v-1c0-1.1-.9-2-2-2h-5Z"/></svg>',
  doors: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M19 14h-3v2h3zm3 7H3V11l8-8h10a1 1 0 0 1 1 1zM11.83 5l-6 6H20V5z"/></svg>',
  access: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="m16 6l3 4h2c1.11 0 2 .89 2 2v3h-2a3 3 0 0 1-3 3a3 3 0 0 1-3-3H9a3 3 0 0 1-3 3a3 3 0 0 1-3-3H1v-3c0-1.11.89-2 2-2l3-4zm-5.5 1.5H6.75L4.86 10h5.64zm1.5 0V10h5.14l-1.89-2.5zm-6 6A1.5 1.5 0 0 0 4.5 15A1.5 1.5 0 0 0 6 16.5A1.5 1.5 0 0 0 7.5 15A1.5 1.5 0 0 0 6 13.5m12 0a1.5 1.5 0 0 0-1.5 1.5a1.5 1.5 0 0 0 1.5 1.5a1.5 1.5 0 0 0 1.5-1.5a1.5 1.5 0 0 0-1.5-1.5"/></svg>',
  windows: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="m22.63 15.5l-2.42-9.65a1 1 0 0 0-1.07-.75c-1.34.14-5 .4-7.14.4s-5.8-.26-7.14-.4a1 1 0 0 0-1.07.75L1.37 15.5a1.5 1.5 0 0 0 1.18 1.86A61.5 61.5 0 0 0 12 18a61.5 61.5 0 0 0 9.45-.64a1.5 1.5 0 0 0 1.18-1.86M12 16a63 63 0 0 1-8.56-.5L5.5 7.18c1.5.14 4.66.32 6.5.32s5-.18 6.5-.32l2.06 8.32A63 63 0 0 1 12 16"/></svg>',
  neon: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M2.95 3L2 6.91l17.34 4.34l.95-3.91zm3.14 3.89l-1.93-.48l.48-1.95l1.93.48zm3.85.97L8 7.38l.5-1.96l1.92.49zm3.86.96l-1.93-.48l.48-1.95l1.92.48zm3.85.97l-1.93-.48l.48-1.96l1.93.49zM4.66 12.75l-.95 3.91L21.05 21l.95-3.9zm3.14 3.9l-1.92-.49l.47-1.95l1.93.48zm3.85.96l-1.92-.48l.47-1.95l1.93.48zm3.85.97l-1.92-.49l.48-1.95l1.94.48zm3.86.96l-1.93-.48l.48-1.95l1.93.48zM6.25 12.11L11 10.2l6.75 1.69L13 13.8z"/></svg>',
};

function postNui(eventName, payload = {}) {
  return fetch(`https://${resourceName}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload),
  }).then((r) => (r && r.json) ? r.json().catch(() => ({})) : {}).catch(() => ({}));
}

function setText(selector, value) {
  const el = document.querySelector(selector);
  if (el && value != null) el.textContent = value;
}

function iconButton(key, title, lit, active) {
  const btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'tool';
  btn.dataset.tool = key;
  btn.title = title || '';
  if (lit) btn.classList.add('lit');
  if (active) btn.classList.add('active');
  btn.innerHTML = ICONS[key] || '';
  return btn;
}

function choiceButton(label, { on = false, disabled = false, mine = false, onClick } = {}) {
  const btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'choice';
  if (on) btn.classList.add('on');
  if (mine) btn.classList.add('mine');
  if (disabled) btn.disabled = true;
  btn.textContent = label;
  if (!disabled && onClick) btn.addEventListener('click', onClick);
  return btn;
}

function closePopover() {
  openTool = null;
  popover.classList.add('hidden');
  popoverBody.replaceChildren();
  document.querySelectorAll('.tool.active').forEach((el) => el.classList.remove('active'));
}

function placePopover(key) {
  const btn = document.querySelector(`[data-tool="${key}"]`);
  if (!btn) return;
  const dock = document.getElementById('dock');
  const left = Math.max(0, btn.offsetLeft);
  const maxLeft = Math.max(0, dock.offsetWidth - popover.offsetWidth);
  popover.style.left = Math.min(left, maxLeft) + 'px';
}

function showPopover(key, title, nodes) {
  if (openTool === key) {
    closePopover();
    return;
  }
  openTool = key;
  popoverTitle.textContent = title || '';
  popoverBody.replaceChildren();
  nodes.forEach((node) => popoverBody.appendChild(node));
  popover.classList.remove('hidden');
  document.querySelectorAll('.tool').forEach((el) => {
    el.classList.toggle('active', el.dataset.tool === key);
  });
  placePopover(key);
}

function seatNodes() {
  return state.seats.map((seat) => {
    const suffix = seat.isMe ? ' (' + ui.stYou + ')' : seat.occupied ? ' (' + ui.stTaken + ')' : '';
    return choiceButton(seat.label + suffix, {
      mine: seat.isMe,
      disabled: seat.isMe || seat.occupied,
      onClick: () => postNui('switchSeat', { seat: seat.index }),
    });
  });
}

function doorNodes() {
  return state.doors.map((door) => choiceButton(door.label + ' · ' + (door.open ? ui.stOpen : ui.stClosed), {
    on: door.open,
    onClick: () => postNui('toggleDoor', { door: door.index, open: !door.open }),
  }));
}

function windowNodes() {
  return state.windows.map((win) => choiceButton(win.label + ' · ' + (win.down ? ui.stOpen : ui.stClosed), {
    on: win.down,
    onClick: () => postNui('toggleWindow', { window: win.index, down: !win.down }),
  }));
}

function accessNodes() {
  const nodes = [];
  if (state.hood) {
    nodes.push(choiceButton(state.hood.label + ' · ' + (state.hood.open ? ui.stOpen : ui.stClosed), {
      on: state.hood.open,
      onClick: () => postNui('toggleHoodTrunk', { which: 'hood', open: !state.hood.open }),
    }));
  }
  if (state.trunk) {
    nodes.push(choiceButton(state.trunk.label + ' · ' + (state.trunk.open ? ui.stOpen : ui.stClosed), {
      on: state.trunk.open,
      onClick: () => postNui('toggleHoodTrunk', { which: 'trunk', open: !state.trunk.open }),
    }));
  }
  return nodes;
}

function renderTools() {
  const previous = openTool;
  toolsEl.replaceChildren();
  const tools = [];

  if (state.engine) {
    const btn = iconButton('engine', ui.secEngine, state.engine.on, false);
    btn.addEventListener('click', () => {
      closePopover();
      postNui('toggleEngine', { on: !state.engine.on });
    });
    tools.push(btn);
  }
  if (state.seats && state.seats.length) {
    const btn = iconButton('seats', ui.secSeats, false, previous === 'seats');
    btn.addEventListener('click', () => showPopover('seats', ui.secSeats, seatNodes()));
    tools.push(btn);
  }
  if (state.doors && state.doors.length) {
    const anyOpen = state.doors.some((door) => door.open);
    const btn = iconButton('doors', ui.secDoors, anyOpen, previous === 'doors');
    btn.addEventListener('click', () => showPopover('doors', ui.secDoors, doorNodes()));
    tools.push(btn);
  }
  if (state.hood || state.trunk) {
    const open = (state.hood && state.hood.open) || (state.trunk && state.trunk.open);
    const btn = iconButton('access', ui.secAccess, open, previous === 'access');
    btn.addEventListener('click', () => showPopover('access', ui.secAccess, accessNodes()));
    tools.push(btn);
  }
  if (state.windows && state.windows.length) {
    const anyDown = state.windows.some((win) => win.down);
    const btn = iconButton('windows', ui.secWindows, anyDown, previous === 'windows');
    btn.addEventListener('click', () => showPopover('windows', ui.secWindows, windowNodes()));
    tools.push(btn);
  }
  if (state.neon) {
    const btn = iconButton('neon', ui.secLights, state.neon.on, false);
    btn.addEventListener('click', () => {
      closePopover();
      postNui('toggleNeon', { on: !state.neon.on });
    });
    tools.push(btn);
  }

  tools.forEach((btn) => toolsEl.appendChild(btn));

  if (previous && document.querySelector(`[data-tool="${previous}"]`)) {
    const refresh = {
      seats: () => showPopover('seats', ui.secSeats, seatNodes()),
      doors: () => showPopover('doors', ui.secDoors, doorNodes()),
      windows: () => showPopover('windows', ui.secWindows, windowNodes()),
      access: () => showPopover('access', ui.secAccess, accessNodes()),
    };
    openTool = null;
    if (refresh[previous]) refresh[previous]();
  } else {
    closePopover();
  }
}

function render() {
  const plate = state.plate ? state.plate.trim() : '';
  const name = state.vehicleName || '';
  setText('#header-plate', [name, plate].filter(Boolean).join(' · '));
  setText('#title', ui.title || 'VEHICLE');
  setText('#close', ui.close || 'Exit');
  renderTools();
}

document.getElementById('close').addEventListener('click', () => postNui('close'));

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') postNui('close');
});

window.addEventListener('message', (event) => {
  const { action, data, locale } = event.data || {};
  if (action === 'open') {
    const savedPos = localStorage.getItem('vehicleInteractPos');
    if (savedPos) {
      try {
        const pos = JSON.parse(savedPos);
        app.style.bottom = 'auto';
        app.style.transform = 'none';
        app.style.left = pos.left;
        app.style.top = pos.top;
      } catch (_) {
        resetPlace();
      }
    } else {
      resetPlace();
    }
    state = data || { ...emptyState };
    if (locale) ui = locale;
    openTool = null;
    app.classList.remove('hidden');
    render();
    requestAnimationFrame(clampIntoView);
  }
  if (action === 'refresh') {
    state = data || { ...emptyState };
    render();
  }
  if (action === 'patch' && data) {
    if (data.kind === 'door') {
      const door = (state.doors || []).find((item) => item.index === data.index);
      if (door) door.open = data.open;
    } else if (data.kind === 'window') {
      const win = (state.windows || []).find((item) => item.index === data.index);
      if (win) win.down = data.down;
    } else if (data.kind === 'hood' && state.hood) {
      state.hood.open = data.open;
    } else if (data.kind === 'trunk' && state.trunk) {
      state.trunk.open = data.open;
    } else if (data.kind === 'engine' && state.engine) {
      state.engine.on = data.on;
    } else if (data.kind === 'neon' && state.neon) {
      state.neon.on = data.on;
    } else if (data.kind === 'seat') {
      (state.seats || []).forEach((seat) => {
        if (seat.index === data.index) {
          seat.isMe = true;
          seat.occupied = true;
        } else if (seat.isMe) {
          seat.isMe = false;
          seat.occupied = false;
        }
      });
    }
    render();
  }
  if (action === 'close') {
    closePopover();
    app.classList.add('hidden');
  }
});

function resetPlace() {
  app.style.top = '';
  app.style.left = '50%';
  app.style.transform = 'translateX(-50%)';
  app.style.bottom = '8vh';
}

function clampIntoView() {
  if (app.style.transform && app.style.transform !== 'none') return;
  const rect = app.getBoundingClientRect();
  const maxLeft = Math.max(0, window.innerWidth - rect.width);
  const maxTop = Math.max(0, window.innerHeight - rect.height);
  const left = Math.min(Math.max(0, rect.left), maxLeft);
  const top = Math.min(Math.max(0, rect.top), maxTop);
  app.style.left = left + 'px';
  app.style.top = top + 'px';
  app.style.bottom = 'auto';
  app.style.transform = 'none';
}

let isDragging = false;
let startX, startY, appX, appY;
const brand = document.getElementById('brand');

brand.addEventListener('mousedown', (event) => {
  isDragging = true;
  startX = event.clientX;
  startY = event.clientY;
  const rect = app.getBoundingClientRect();
  appX = rect.left;
  appY = rect.top;
  app.style.bottom = 'auto';
  app.style.transform = 'none';
  app.style.left = appX + 'px';
  app.style.top = appY + 'px';
});

document.addEventListener('mousemove', (event) => {
  if (!isDragging) return;
  app.style.left = (appX + event.clientX - startX) + 'px';
  app.style.top = (appY + event.clientY - startY) + 'px';
  clampIntoView();
});

document.addEventListener('mouseup', () => {
  if (isDragging) {
    clampIntoView();
    localStorage.setItem('vehicleInteractPos', JSON.stringify({ left: app.style.left, top: app.style.top }));
  }
  isDragging = false;
});

window.addEventListener('resize', () => {
  if (!app.classList.contains('hidden')) clampIntoView();
});
