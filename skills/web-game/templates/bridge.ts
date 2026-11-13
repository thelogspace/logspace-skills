// Game ↔ Flutter shell bridge (logspace:web-game). The shell uses the official webview_flutter:
// game → shell through the JavaScript channel window.logspace.postMessage(json),
// shell → game through window.logspaceBridge.receive(message). A no-op in the browser.

export type ToHost = { type: 'ready' } | { type: 'haptic'; kind: 'light' | 'medium' | 'heavy' };

export type FromHost = { type: 'setLocale'; locale: string } | { type: 'pause' } | { type: 'resume' };

type HostWindow = {
  logspace?: { postMessage(message: string): void };
  logspaceBridge?: { receive(message: FromHost): void };
};

const listeners = new Set<(message: FromHost) => void>();

export function isHosted(w: HostWindow = window as HostWindow): boolean {
  return typeof w.logspace?.postMessage === 'function';
}

export function send(message: ToHost, w: HostWindow = window as HostWindow): void {
  const channel = w.logspace;
  if (typeof channel?.postMessage !== 'function') return;
  channel.postMessage(JSON.stringify(message));
}

export function onMessage(listener: (message: FromHost) => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function install(w: HostWindow = window as HostWindow): void {
  w.logspaceBridge = {
    receive(message) {
      for (const l of listeners) l(message);
    },
  };
}
