'use strict';

const path = require('path');
const fs = require('fs');
const { app, BrowserWindow, Menu, shell } = require('electron');

let Store;
try {
  // electron-store is ESM-only since v9; load lazily and tolerate absence.
  Store = require('electron-store');
} catch (_) {
  Store = null;
}

const APP_NAME = (() => {
  try {
    const cfg = JSON.parse(fs.readFileSync(
      path.join(__dirname, '..', 'release.config.json'), 'utf8'));
    return cfg.displayName || cfg.appName || app.getName();
  } catch (_) {
    return app.getName();
  }
})();

app.setName(APP_NAME);

function loadWindowState() {
  if (!Store) return { width: 1280, height: 800 };
  try {
    const store = new Store({ name: 'window-state' });
    return store.get('main', { width: 1280, height: 800 });
  } catch (_) {
    return { width: 1280, height: 800 };
  }
}

function saveWindowState(win) {
  if (!Store) return;
  try {
    const store = new Store({ name: 'window-state' });
    const b = win.getBounds();
    store.set('main', b);
  } catch (_) { /* ignore */ }
}

function createWindow() {
  const state = loadWindowState();
  const win = new BrowserWindow({
    width:  state.width  || 1280,
    height: state.height || 800,
    x:      state.x,
    y:      state.y,
    title:  APP_NAME,
    backgroundColor: '#101010',
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  // External links open in the user's browser, not in-app.
  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  // Persist window bounds.
  ['close', 'resize', 'move'].forEach((ev) => {
    win.on(ev, () => saveWindowState(win));
  });

  // Load the marketing/web index.html that lives one dir above /desktop.
  const indexPath = path.join(__dirname, '..', 'index.html');
  if (fs.existsSync(indexPath)) {
    win.loadFile(indexPath);
  } else {
    win.loadURL(
      'data:text/html;charset=utf-8,' +
      encodeURIComponent(
        `<!doctype html><html><body style="font-family:sans-serif;` +
        `background:#101010;color:#eee;padding:48px"><h1>${APP_NAME}</h1>` +
        `<p>index.html not found at ${indexPath}</p></body></html>`
      )
    );
  }

  Menu.setApplicationMenu(buildMenu(win));
  return win;
}

function buildMenu(win) {
  const isMac = process.platform === 'darwin';
  const template = [
    ...(isMac ? [{
      label: APP_NAME,
      submenu: [
        { role: 'about' },
        { type: 'separator' },
        { role: 'services' },
        { type: 'separator' },
        { role: 'hide' },
        { role: 'hideOthers' },
        { role: 'unhide' },
        { type: 'separator' },
        { role: 'quit' }
      ]
    }] : []),
    {
      label: 'File',
      submenu: [
        isMac ? { role: 'close' } : { role: 'quit' }
      ]
    },
    { label: 'Edit',   submenu: [
      { role: 'undo' }, { role: 'redo' }, { type: 'separator' },
      { role: 'cut' }, { role: 'copy' }, { role: 'paste' }
    ]},
    { label: 'View',   submenu: [
      { role: 'reload' }, { role: 'forceReload' }, { type: 'separator' },
      { role: 'resetZoom' }, { role: 'zoomIn' }, { role: 'zoomOut' },
      { type: 'separator' },
      { role: 'togglefullscreen' },
      { role: 'toggleDevTools' }
    ]},
    { role: 'windowMenu' },
    { label: 'Help',   submenu: [
      {
        label: 'Open marketing site',
        click: () => shell.openExternal('https://americangroupllc.github.io/')
      }
    ]}
  ];
  return Menu.buildFromTemplate(template);
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
