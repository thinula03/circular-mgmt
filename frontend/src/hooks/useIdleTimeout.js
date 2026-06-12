import { useEffect, useRef } from "react";

// FR-03: auto-terminate inactive sessions after 30 minutes.
// Resets the countdown on any user activity; fires onIdle when the user has
// been inactive for `timeoutMs`.
const DEFAULT_TIMEOUT = 30 * 60 * 1000; // 30 minutes

export default function useIdleTimeout(onIdle, timeoutMs = DEFAULT_TIMEOUT) {
  const timer = useRef(null);

  useEffect(() => {
    const reset = () => {
      if (timer.current) clearTimeout(timer.current);
      timer.current = setTimeout(onIdle, timeoutMs);
    };
    const events = ["mousemove", "mousedown", "keydown", "scroll", "touchstart"];
    events.forEach((e) => window.addEventListener(e, reset, { passive: true }));
    reset(); // start the clock

    return () => {
      if (timer.current) clearTimeout(timer.current);
      events.forEach((e) => window.removeEventListener(e, reset));
    };
  }, [onIdle, timeoutMs]);
}
