# Changelog

All notable changes to CRGGR.sh are recorded here. Dates are when a version was
released, not when a change merged. Everything up to and including 0.5.6 shipped
under the name TRMNL.

## [0.6.0] - 2026-09-04

### Changed

- **TRMNL is now CRGGR.sh.** New name, new app icon, new installer. Profiles,
  keybindings and saved layouts migrate automatically on first launch. Two
  one-time consequences: macOS treats this as a new app, so it asks again for
  Automation and Accessibility permissions, and the old `TRMNL.app` is left in
  place rather than replaced.
- **The front end is rebuilt on the GRID design system.** A command block is now
  a panel, and its state *is* the panel: a settled command sits in a quiet grey
  frame, the one being read is brightened with a filled header, a failure turns
  the whole frame red, and something still running turns it cyan. Exit status is
  the shape of the block rather than a chip you have to go looking for.
- **Colour is a signal, never decoration.** The six identities and the accent
  picker are gone. Amber marks what you are acting on, cyan what is live, green
  success, red failure — and nothing is coloured for any other reason.
- **The interface holds still.** The boot sequence, identity sweep, divider
  trace, blinking caret and pulsing status dot are all removed. Nothing animates
  and nothing fades in; the only thing that moves is the real cursor inside an
  interactive program.

### Added

- **A PANELS settings pane** for the frame geometry every block is drawn with —
  border width, corner style, frame gap, heading size. It redraws as you change
  it, since the settings window is a panel too.

### Fixed

- A clean exit is no longer reported as an error. Closing a shell with `exit` or
  ⌃D painted the pane in the error colour, which called a shell doing exactly
  what it was told a failure. Only a non-zero exit code gets the red treatment.
- Escape could close two dialogs at once.
- The "did you mean" error renderer shouted the shell's own words back in the
  app's voice.
- Block action buttons faded in where they should have appeared instantly.

## [0.5.6] - 2026-08-06

### Fixed

- A finished interactive session no longer vanishes before it can be read. A
  full-screen program (vim, `shopify theme dev`) snapped back to the block view
  the instant it exited, taking whatever it had just printed with it. The last
  frame now stays on screen until dismissed with the EXIT button.

## [0.5.5] - 2026-08-04

### Added

- **Clickable links and context-menu copy actions.** Bare URLs in a command's
  output are detected and ⌘-clickable, with "Copy Link" / "Copy Text" on
  right-click, including inside takeover-mode sessions. The takeover header
  gains a manual `⌃C EXIT` button.
- **Confirmation before killing a live process.** Closing a session or pane
  while a command is still running now asks first, rather than killing it.

### Fixed

- Real exit codes are captured from the shell, so a session whose shell exits on
  its own shows a `PROCESS EXITED (CODE N)` banner instead of silently going
  inert.

## [0.5.0] - 2026-08-04

### Added

- **Test-runner structured renderer.** `npm test`, `vitest`, `jest` and
  `cargo test` output is now parsed into a pass/fail/skipped summary with
  failed test names as chips, instead of falling back to plain scrollback
  text. Toggle under Settings → Behavior → Output Renderers. Follows the
  existing renderer contract: ambiguous output always falls back to text.
- **Copy block as markdown.** A fourth block action, `COPY MD`, alongside
  `COPY OUT` / `COPY CMD` / `RERUN`. Fences the command, its output, and exit
  status/duration as a single snippet for pasting into a PR description,
  issue, or chat message.
- **Pane focus mode.** `⌘⇧M` temporarily maximizes the focused pane to fill
  the window when split, and restores the prior split geometry on a second
  press. The hidden pane's session keeps running in the background.
- **Keybinding editor.** The `EDIT` control in Settings → Keybindings now
  works: click it, press a chord, and it's captured, checked for collisions
  against every other binding, and saved immediately. A collision prompts an
  explicit REPLACE rather than silently overwriting, and swaps the two
  actions' chords so neither is left unbound. Covers the ten actions handled
  by the app's global keydown handler; `⌘,`/`⌘T`/`⌘W` (native macOS menu
  items) and `⇥` (tied to completion) remain fixed, and `⌃C` remains
  permanent.
- **Per-pane session tabs.** The vertical session rail is replaced by a
  horizontal tab strip above each pane's header — closer to how iTerm/Warp/
  VS Code do it, and each pane now visibly owns exactly the sessions in its
  own strip. Tabs support drag-to-reorder within a pane and double-click to
  rename a session independently of its profile name.
- **Full-width status bar.** CPU, memory, load average, disk free, and
  network telemetry — previously the rail's footer — now runs as one row
  along the bottom of the frame.

### Fixed

- The session close button (rail row, now tab) could silently fail to
  register a click: it was invisible until the row's `:hover` state revealed
  it, and a normal cursor move onto the button could drop that hover state
  mid-click. It's now always present and hit-testable, dimmed rather than
  hidden at rest.
- Buttons and the session/tab row now show a pointer cursor instead of the
  default arrow, matching normal expectations for interactive elements.

## [0.4.2] - 2026-08-04

- Refuse a plaintext notarization password, and name unknown config keys.
- Let the builder supply their own signing identity via `.env.local` or the
  environment, rather than a hardcoded default.

## [0.4.1] - 2026-08-04

- Make profiles global in fact, not just in intent — a profile added in one
  window is now reachable from every other.
- Rust owns sessions, so a window is just a view onto them; multiple windows
  can now share session state correctly.
- Add a one-step install into `/Applications` (`npm run app:install`).
