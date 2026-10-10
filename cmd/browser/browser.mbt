///|
/// Creates an isolated content context. Invalid input fails before a context is
/// returned, so existing contexts remain usable after a failed replacement.
pub fn create_renderer(
  site_json : String,
  resume_json : String,
) -> @portfolio.Renderer {
  @portfolio.Renderer::new(site_json, resume_json) catch {
    @portfolio.InvalidConfig(message) =>
      abort("create_renderer: invalid configuration: \{message}")
  }
}

///|
/// Renders using an explicitly supplied content context.
pub fn render_with(
  renderer : @portfolio.Renderer,
  path : String,
  year : Int,
) -> String {
  renderer.render_page(path, year) catch {
    @portfolio.InvalidConfig(message) =>
      abort("render_with: invalid configuration: \{message}")
  }
}

///|
/// Builds metadata using an explicitly supplied content context.
pub fn metadata_with(renderer : @portfolio.Renderer, path : String) -> String {
  renderer.page_metadata(path) catch {
    @portfolio.InvalidConfig(message) =>
      abort("metadata_with: invalid configuration: \{message}")
  }
}

///|
/// Renders the complete site shell for a request path.
///
/// `path` may carry a trailing slash, a query string, or a fragment. The
/// browser export returns a plain `String`, so it cannot carry a `Result`:
/// invalid content JSON aborts explicitly instead of rendering a partial page.
pub fn render_page(
  path : String,
  site_json : String,
  resume_json : String,
  year : Int,
) -> String {
  @portfolio.render_page(path, site_json, resume_json, year) catch {
    @portfolio.InvalidConfig(message) =>
      abort("render_page: invalid configuration: \{message}")
  }
}

///|
/// Serialized social metadata for a request path.
///
/// The browser export returns a plain `String`; invalid content JSON aborts
/// explicitly rather than wrapping the serialized JSON in a `Result`.
pub fn page_metadata(
  path : String,
  site_json : String,
  resume_json : String,
) -> String {
  @portfolio.page_metadata(path, site_json, resume_json) catch {
    @portfolio.InvalidConfig(message) =>
      abort("page_metadata: invalid configuration: \{message}")
  }
}

///|
/// HTTP status for a request path: 200 for a known route, 404 otherwise.
pub fn route_status(path : String) -> Int {
  @portfolio.route_status(path)
}

///|
/// The theme a client switches to next.
pub fn toggle_theme(current : String) -> String {
  @portfolio.toggle_theme(current)
}

///|
/// Flips the navigation menu state.
pub fn toggle_menu(open : Bool) -> Bool {
  @portfolio.toggle_menu(open)
}

///|
/// Browser entry point.
///
/// The host drives this package by calling the exported functions above, so the
/// executable has no startup work of its own.
fn main {
  ()
}
