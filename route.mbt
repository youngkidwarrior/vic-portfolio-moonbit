///|
/// Project slugs the portfolio knows about.
///
/// The set is closed so a request path and a content entry can both be
/// validated against it instead of being carried around as unchecked strings.
pub enum ProjectSlug {
  Send
  Shenanigan
  BrightId
  OpenSource
}

///|
/// Every known slug, in the order the home page lists them.
pub fn ProjectSlug::all() -> Array[ProjectSlug] {
  [Send, Shenanigan, BrightId, OpenSource]
}

///|
/// The URL and artwork name of a slug: `send`, `shenanigan`, `brightid`,
/// `open-source`.
pub fn ProjectSlug::slug(self : ProjectSlug) -> String {
  match self {
    Send => "send"
    Shenanigan => "shenanigan"
    BrightId => "brightid"
    OpenSource => "open-source"
  }
}

///|
/// Parses a slug from content or a URL. Unknown slugs return `None` so a
/// route can report 404 while content parsing can raise the same failure.
pub fn ProjectSlug::from_slug(slug : String) -> ProjectSlug? {
  match slug {
    "send" => Some(Send)
    "shenanigan" => Some(Shenanigan)
    "brightid" => Some(BrightId)
    "open-source" => Some(OpenSource)
    _ => None
  }
}

///|
/// Accent names used by the copied stylesheet for `project-<accent>` classes
/// and the per-project color variables.
pub enum Accent {
  Cobalt
  Red
  Green
  Yellow
}

///|
/// The stylesheet class suffix for an accent.
pub fn Accent::name(self : Accent) -> String {
  match self {
    Cobalt => "cobalt"
    Red => "red"
    Green => "green"
    Yellow => "yellow"
  }
}

///|
/// Parses an accent name from content.
pub fn Accent::from_name(name : String) -> Accent? {
  match name {
    "cobalt" => Some(Cobalt)
    "red" => Some(Red)
    "green" => Some(Green)
    "yellow" => Some(Yellow)
    _ => None
  }
}

///|
/// The routes the portfolio server renders.
///
/// Route interpretation is typed: an unknown path becomes `Route::NotFound`
/// rather than flowing through as a raw string.
pub enum Route {
  Home
  CaseStudy(ProjectSlug)
  Resume
  NotFound
}

///|
/// Normalizes a request path for matching and for canonical URLs.
///
/// Query strings and fragments are dropped, leading, trailing, and repeated
/// slashes are collapsed, and the result always starts with `/`. The root path
/// normalizes to `/`.
///
/// ```text
/// "/resume/?x=1"       -> "/resume"
/// "/work//send#top"    -> "/work/send"
/// ""                   -> "/"
/// ```
pub fn normalize_path(path : String) -> String {
  let mut cut = path.length()
  let mut index = 0
  while index < path.length() {
    let ch = path[index]
    if ch == '?' || ch == '#' {
      cut = index
      break
    }
    index += 1
  }
  let result = StringBuilder()
  result.write_char('/')
  let mut pending_slash = false
  let mut seen_content = false
  for ch in path[:cut] {
    if ch == '/' {
      if seen_content {
        pending_slash = true
      }
    } else {
      if pending_slash {
        result.write_char('/')
        pending_slash = false
      }
      result.write_char(ch)
      seen_content = true
    }
  }
  result.to_string()
}

///|
/// Resolves a request path to a route, tolerating trailing slashes, query
/// strings, and fragments.
pub fn Route::from_path(path : String) -> Route {
  let normalized = normalize_path(path)
  if normalized == "/" {
    Home
  } else if normalized == "/resume" {
    Resume
  } else if normalized.has_prefix("/work/") {
    match ProjectSlug::from_slug(normalized[6:].to_owned()) {
      Some(slug) => CaseStudy(slug)
      None => NotFound
    }
  } else {
    NotFound
  }
}

///|
/// HTTP status for a request path: 200 for a known route, 404 for anything else.
pub fn route_status(path : String) -> Int {
  match Route::from_path(path) {
    NotFound => 404
    _ => 200
  }
}
