// Game ↔ Flutter shell bridge. Works as a no-op in the browser (pnpm dev, tests).

export type ToHost =
  | { type: 'ready' }
  | { type: 'analytics'; name: string; params?: Record<string, string | number> }
  | { type: 'showRewarded'; placement: string }
  | { type: 'showInterstitial'; placement: string }
  | { type: 'haptic'; kind: 'light' | 'medium' | 'heavy' };

export type FromHost =
  | { type: 'setLocale'; locale: string }
  | { type: 'pause' }
  | { type: 'resume' }
  | { type: 'rewardResult'; placement: string; rewarded: boolean };

type HostWindow = Window & {
  flutter_inappwebview?: { callHandler(name: string, ...args: unknown[]): Promise<unknown> };
  logspaceBridge?: { receive(message: FromHost): void };
};

const HANDLER = 'logspace';
const listeners = new Set<(message: FromHost) => void>();

export function isHosted(w: HostWindow = window): boolean {
  return typeof w.flutter_inappwebview?.callHandler === 'function';
}

export function send(message: ToHost, w: HostWindow = window): void {
  if (!isHosted(w)) return;
  void w.flutter_inappwebview!.callHandler(HANDLER, JSON.stringify(message));
}

export function onMessage(listener: (message: FromHost) => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function install(w: HostWindow = window): void {
  w.logspaceBridge = {
    receive(message) {
      for (const l of listeners) l(message);
    },
  };
}
