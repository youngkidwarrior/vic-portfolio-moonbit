///|
/// Renders the theme control.
///
/// The server renders the light state: the label says what the next tap does.
/// The dark-state icon is in the markup but hidden, so a client can swap the
/// two without rebuilding the button.
fn theme_button() -> String {
  let html =
    $|<button class="icon-button" type="button" data-action="theme" aria-label="Switch to dark theme"><span class="theme-symbol">\{icon_moon()}</span><span class="theme-symbol theme-symbol-sun" hidden>\{icon_sun()}</span></button>
  html
}

///|
/// Renders the navigation menu control in its closed state.
fn menu_button() -> String {
  let html =
    $|<button class="icon-button menu-button" type="button" data-action="menu" aria-controls="primary-navigation" aria-expanded="false" aria-label="Toggle navigation"><span class="menu-symbol" data-state="closed">\{icon_list()}</span><span class="menu-symbol" data-state="open" hidden>\{icon_close()}</span></button>
  html
}

///|
/// Renders the site header: skip link, brand, primary navigation, and the two
/// state controls.
fn site_header(site : Site) -> String {
  let brand_label = "VG, \{site.name} home"
  let html =
    $|<header class="site-header">
    $|<a class="skip-link" href="#main-content">Skip to content</a>
    $|<div class="nav-shell">
    $|<a class="brand" href="/" aria-label="\{esc(brand_label)}"><span class="brand-mark">VG</span><span>\{esc(site.name)}</span></a>
    $|<nav id="primary-navigation" class="primary-nav" aria-label="Primary">
    $|<a href="/#work">Work</a>
    $|<a href="/#about">About</a>
    $|<a href="/resume">Resume</a>
    $|<a href="mailto:\{esc(site.email)}">Contact</a>
    $|</nav>
    $|<div class="nav-actions">
    $|\{theme_button()}
    $|\{menu_button()}
    $|</div>
    $|</div>
    $|</header>
  html
}

///|
/// Renders the site footer with the year the renderer was given.
fn site_footer(site : Site, year : Int) -> String {
  let html =
    $|<footer class="site-footer">
    $|<div class="reveal-motion" data-reveal>
    $|<p class="footer-callout">Building something ambitious?</p>
    $|<a class="footer-email" href="mailto:\{esc(site.email)}">Get in touch \{icon_arrow_up_right()}</a>
    $|</div>
    $|<div class="footer-links">
    $|<a href="\{esc(site.github)}" target="_blank" rel="noreferrer">GitHub</a>
    $|<a href="\{esc(site.resume_pdf)}">PDF resume</a>
    $|<span>© \{year} \{esc(site.name)}</span>
    $|</div>
    $|</footer>
  html
}

///|
/// Wraps route content in the document's main landmark.
fn wrap_main(content : String) -> String {
  let html =
    $|<main id="main-content" tabindex="-1">
    $|\{content}
    $|</main>
  html
}

///|
/// Renders the whole site shell around a route body.
fn render_shell(site : Site, body : String, year : Int) -> String {
  let html =
    $|<div class="site-shell">
    $|\{site_header(site)}
    $|\{body}
    $|\{site_footer(site, year)}
    $|</div>
  html
}
