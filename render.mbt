///|
/// The theme a client reports, normalized to the two values the stylesheet
/// understands.
pub enum Theme {
  Light
  Dark
}

///|
/// Normalizes a stored theme name. Anything other than `"dark"` is light, which
/// is what the original toggle did with an unset `localStorage` value.
pub fn Theme::from_name(name : String) -> Theme {
  if name == "dark" {
    Dark
  } else {
    Light
  }
}

///|
/// The stored name of a theme.
pub fn Theme::name(self : Theme) -> String {
  match self {
    Light => "light"
    Dark => "dark"
  }
}

///|
/// The opposite theme.
pub fn Theme::next(self : Theme) -> Theme {
  match self {
    Light => Dark
    Dark => Light
  }
}

///|
/// The theme a client switches to next.
pub fn toggle_theme(current : String) -> String {
  Theme::from_name(current).next().name()
}

///|
/// Flips the navigation menu state.
pub fn toggle_menu(open : Bool) -> Bool {
  !open
}

///|
/// Looks up the project a case-study route renders.
fn require_project(
  site : Site,
  slug : ProjectSlug,
) -> Project raise PortfolioError {
  match site.project(slug) {
    Some(project) => project
    None =>
      raise InvalidConfig("site.json: no project for slug \"\{slug.slug()}\"")
  }
}

///|
/// Removes trailing slashes from a base URL.
fn without_trailing_slashes(value : String) -> String {
  let mut end = value.length()
  while end > 0 && value[end - 1] == '/' {
    end -= 1
  }
  value[:end].to_owned()
}

///|
/// Builds an absolute URL from the configured site URL and a normalized path.
fn absolute_url(base : String, path : String) -> String {
  "\{without_trailing_slashes(base)}\{path}"
}

///|
/// Renders the body of a matched route.
fn render_route(
  route : Route,
  site : Site,
  resume_content : Resume,
  path : String,
) -> String raise PortfolioError {
  match route {
    Home => wrap_main(home_page(site))
    CaseStudy(slug) => wrap_main(case_page(require_project(site, slug)))
    Resume => wrap_main(resume_page(site, resume_content))
    NotFound => wrap_main(not_found_page(path))
  }
}

///|
/// The document title of the home page, kept as the original site title.
fn home_title(site : Site) -> String {
  "\{site.name} | \{site.role}"
}

///|
/// Validated content owned by one renderer. Private fields prevent callers from
/// mutating the parsed arrays; each context is independent and has no cache.
pub struct Renderer {
  priv site : Site
  priv resume_content : Resume
}

///|
/// Parses both documents before publishing a usable renderer.
pub fn Renderer::new(
  site_json : String,
  resume_json : String,
) -> Renderer raise PortfolioError {
  let site = Site::from_json_text(site_json)
  let resume_content = Resume::from_json_text(resume_json)
  { site, resume_content, }
}

///|
/// Renders the complete site shell for a request path.
///
/// `path` may carry a trailing slash, a query string, or a fragment; it is
/// normalized before matching. Invalid content raises `PortfolioError` instead
/// of rendering a partial page.
pub fn render_page(
  path : String,
  site_json : String,
  resume_json : String,
  year : Int,
) -> String raise PortfolioError {
  Renderer::new(site_json, resume_json).render_page(path, year)
}

///|
/// Renders with previously validated content and the current request year.
pub fn Renderer::render_page(
  self : Renderer,
  path : String,
  year : Int,
) -> String raise PortfolioError {
  let site = self.site
  let resume_content = self.resume_content
  let normalized = normalize_path(path)
  let route = Route::from_path(normalized)
  let body = render_route(route, site, resume_content, normalized)
  render_shell(site, body, year)
}

///|
/// Serialized social metadata for a request path: `{title, description,
/// canonical, image}` with absolute URLs.
pub fn page_metadata(
  path : String,
  site_json : String,
  resume_json : String,
) -> String raise PortfolioError {
  Renderer::new(site_json, resume_json).page_metadata(path)
}

///|
/// Builds metadata from the same validated content as the rendered body.
pub fn Renderer::page_metadata(
  self : Renderer,
  path : String,
) -> String raise PortfolioError {
  let site = self.site
  let resume_content = self.resume_content
  let normalized = normalize_path(path)
  let route = Route::from_path(normalized)
  let (title, description, image) = match route {
    Home => (home_title(site), site.description, site.social_image)
    CaseStudy(slug) => {
      let project = require_project(site, slug)
      ("\{project.title} | \{site.name}", project.lede, project.screenshot.src)
    }
    Resume =>
      ("Resume | \{site.name}", resume_content.profile, site.social_image)
    NotFound =>
      (
        "Page not found | \{site.name}",
        "This page could not be found.",
        site.social_image,
      )
  }
  let metadata : Json = {
    "title": title,
    "description": description,
    "canonical": absolute_url(site.url, normalized),
    "image": absolute_url(site.url, image),
  }
  metadata.stringify()
}
