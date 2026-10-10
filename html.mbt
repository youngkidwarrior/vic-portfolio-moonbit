///|
/// Escapes text for HTML text and attribute positions.
///
/// Every value that comes from content JSON or from a request goes through
/// this function, so a title with `<`, `"`, or `&` stays text instead of
/// becoming markup.
fn esc(value : String) -> String {
  @template.escape_html(value)
}

///|
/// Appends a trusted markup fragment.
fn emit(out : StringBuilder, html : String) -> Unit {
  out.write_string(html)
}

///|
/// Decorative arrow pointing up and to the right.
fn icon_arrow_up_right() -> String {
  let svg =
    #|<svg viewBox="0 0 256 256" width="1em" height="1em" fill="none" stroke="currentColor" stroke-width="24" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M64 192 192 64"/><path d="M104 64h88v88"/></svg>
  svg
}

///|
/// Decorative arrow pointing down and to the right.
fn icon_arrow_down_right() -> String {
  let svg =
    #|<svg viewBox="0 0 256 256" width="1em" height="1em" fill="none" stroke="currentColor" stroke-width="24" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M64 64 192 192"/><path d="M192 104v88h-88"/></svg>
  svg
}

///|
/// Decorative arrow pointing left.
fn icon_arrow_left() -> String {
  let svg =
    #|<svg viewBox="0 0 256 256" width="1em" height="1em" fill="none" stroke="currentColor" stroke-width="24" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M216 128H40"/><path d="M112 56 40 128l72 72"/></svg>
  svg
}

///|
/// Decorative arrow pointing down.
fn icon_arrow_down() -> String {
  let svg =
    #|<svg viewBox="0 0 256 256" width="1em" height="1em" fill="none" stroke="currentColor" stroke-width="24" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M128 40v176"/><path d="M56 144l72 72 72-72"/></svg>
  svg
}

///|
/// Decorative crescent used by the theme control's initial light-theme state.
fn icon_moon() -> String {
  let svg =
    #|<svg viewBox="0 0 256 256" width="19" height="19" fill="currentColor" aria-hidden="true" focusable="false"><path d="M224 152a104 104 0 0 1-120-120 104 104 0 1 0 120 120Z"/></svg>
  svg
}

///|
/// Decorative sun that replaces the crescent in the dark theme.
fn icon_sun() -> String {
  let svg =
    #|<svg viewBox="0 0 256 256" width="19" height="19" fill="none" stroke="currentColor" stroke-width="16" stroke-linecap="round" aria-hidden="true" focusable="false"><circle cx="128" cy="128" r="48"/><path d="M128 24v16M128 216v16M40 128H24M232 128h-16M60 60 48 48M208 208l-12-12M60 196l-12 12M208 48l-12 12"/></svg>
  svg
}

///|
/// Decorative list icon for the closed navigation menu button.
fn icon_list() -> String {
  let svg =
    #|<svg viewBox="0 0 256 256" width="20" height="20" fill="none" stroke="currentColor" stroke-width="20" stroke-linecap="round" aria-hidden="true" focusable="false"><path d="M40 64h176M40 128h176M40 192h176"/></svg>
  svg
}

///|
/// Decorative close icon for the open navigation menu button.
fn icon_close() -> String {
  let svg =
    #|<svg viewBox="0 0 256 256" width="20" height="20" fill="none" stroke="currentColor" stroke-width="20" stroke-linecap="round" aria-hidden="true" focusable="false"><path d="M56 56 200 200M200 56 56 200"/></svg>
  svg
}

///|
/// Appends `text` with a trailing period when it has none, so the hero role
/// reads as the original sentence while still coming from `site.role`.
fn with_period(text : String) -> String {
  if text.length() > 0 && text[text.length() - 1] == '.' {
    text
  } else {
    "\{text}."
  }
}
