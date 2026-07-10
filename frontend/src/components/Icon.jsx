// Lightweight inline SVG icon set (outline style) — replaces emoji throughout the
// UI for a professional, consistent look. Icons inherit the current text colour.
const PATHS = {
  bank: [
    "M3 9.5 12 4l9 5.5",
    "M4 11h16",
    "M4 20h16",
    "M6 20v-9M10 20v-9M14 20v-9M18 20v-9",
  ],
  document: [
    "M14 3H7a1 1 0 0 0-1 1v16a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1V7l-4-4z",
    "M14 3v4h4",
    "M9 13h6M9 17h4",
  ],
  chart: ["M4 20h16", "M7 20v-6M12 20V8M17 20v-9"],
  upload: ["M12 16V5", "M8 9l4-4 4 4", "M5 16v2a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-2"],
  users: [
    "M8 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6z",
    "M2 20a6 6 0 0 1 12 0",
    "M15 5.2a3 3 0 0 1 0 5.6",
    "M16 14.3a6 6 0 0 1 4 5.7",
  ],
  bell: [
    "M6 9a6 6 0 1 1 12 0c0 3.5 1 4.5 2 5.5H4c1-1 2-2 2-5.5z",
    "M10 19a2 2 0 0 0 4 0",
  ],
  check: ["M5 12l5 5L19 7"],
  eye: ["M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z", "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z"],
  plus: ["M12 5v14", "M5 12h14"],
  history: ["M3 12a9 9 0 1 0 3-6.7L3 8", "M3 4v4h4", "M12 8v4l3 2"],
  trash: ["M4 7h16", "M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2", "M6 7l1 13h10l1-13"],
  chat: [
    "M4 5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4v-4H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z",
  ],
  expand: [
    "M4 9V5a1 1 0 0 1 1-1h4", "M20 9V5a1 1 0 0 0-1-1h-4",
    "M4 15v4a1 1 0 0 0 1 1h4", "M20 15v4a1 1 0 0 1-1 1h-4",
  ],
  minimize: [
    "M9 4v4H5", "M15 4v4h4", "M9 20v-4H5", "M15 20v-4h4",
  ],
  inbox: [
    "M4 13h4l1.5 2.5h5L16 13h4",
    "M5 5h14l1.5 8v4a1 1 0 0 1-1 1H4.5a1 1 0 0 1-1-1v-4L5 5z",
  ],
  sparkles: [
    "M12 3l1.7 4.6L18 9l-4.3 1.4L12 15l-1.7-4.6L6 9l4.3-1.4L12 3z",
    "M18.5 14l.9 2.4 2.6.9-2.6.9-.9 2.4-.9-2.4-2.6-.9 2.6-.9.9-2.4z",
  ],
};

export default function Icon({ name, className = "h-5 w-5" }) {
  const d = PATHS[name];
  if (!d) return null;
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {d.map((p, i) => (
        <path key={i} d={p} />
      ))}
    </svg>
  );
}
