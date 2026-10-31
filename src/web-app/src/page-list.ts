// Page list disclosure: closed on a phone, open as a sidebar on desktop (ADR-002).
// The 900px breakpoint matches the media queries in style.css.
export const MOBILE_QUERY = '(max-width: 900px)';

interface Disclosure { open: boolean }
interface MediaQuery {
  matches: boolean;
  addEventListener(type: 'change', listener: () => void): void;
}

export function syncPageList(pageList: Disclosure, mobile: MediaQuery): void {
  const sync = () => { pageList.open = !mobile.matches; };
  sync();
  mobile.addEventListener('change', sync);
}
