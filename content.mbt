///|
/// Failure raised while reading or rendering portfolio content.
///
/// Bad configuration is never rendered silently: the message names the JSON
/// location that failed, so a broken `site.json` or `resume.json` stops the
/// render instead of producing a half-empty page.
pub suberror PortfolioError {
  InvalidConfig(String)
}

///|
/// Screenshot metadata used by a project row and by its case study.
pub struct Screenshot {
  src : String
  webp_src : String
  href : String
  width : Int
  height : Int
  alt : String
  caption : String
}

///|
/// One scope-of-work entry: the label on the home page, the detail on the case
/// study.
pub struct Contribution {
  title : String
  detail : String
}

///|
/// An external project link.
pub struct ProjectLink {
  label : String
  href : String
}

///|
/// A highlight: shown as a row on the home page and as its own case study.
pub struct Project {
  slug : ProjectSlug
  title : String
  period : String
  role : String
  lede : String
  accent : Accent
  links : Array[ProjectLink]
  screenshot : Screenshot
  contributions : Array[Contribution]
}

///|
/// A supporting proof link for the recognition headline.
pub struct Proof {
  label : String
  source : String
}

///|
/// The recognition block copied from the original portfolio.
pub struct Recognition {
  headline : String
  supporting_proof : Array[Proof]
}

///|
/// The site configuration and its project list, read from `site.json`.
pub struct Site {
  name : String
  role : String
  url : String
  social_image : String
  email : String
  github : String
  resume_pdf : String
  description : String
  projects : Array[Project]
  recognition : Recognition
}

///|
/// One line of the technical range.
pub struct Skill {
  label : String
  items : String
}

///|
/// One role on the resume.
pub struct Experience {
  company : String
  role : String
  period : String
  bullets : Array[String]
}

///|
/// The recognition entry on the resume.
pub struct ResumeRecognition {
  title : String
  detail : String
}

///|
/// The education entry on the resume.
pub struct Education {
  school : String
  detail : String
}

///|
/// The resume, read from `resume.json`.
pub struct Resume {
  name : String
  title : String
  location : String
  email : String
  website : String
  profile : String
  experience : Array[Experience]
  skills : Array[Skill]
  recognition : ResumeRecognition
  education : Education
}

///|
/// Parses a JSON document, reporting the source name on malformed input.
fn parse_json(text : String, source : String) -> Json raise PortfolioError {
  @json.parse(text) catch {
    error => raise InvalidConfig("\{source}: invalid JSON (\{error})")
  }
}

///|
/// Requires a JSON object.
fn entries(
  json : Json,
  context : String,
) -> Map[String, Json] raise PortfolioError {
  match json {
    Object(entries) => entries
    _ => raise InvalidConfig("\{context}: expected a JSON object")
  }
}

///|
/// Reads a required field of a JSON object.
fn field(
  json : Json,
  name : String,
  context : String,
) -> Json raise PortfolioError {
  match entries(json, context).get(name) {
    Some(value) => value
    None => raise InvalidConfig("\{context}: missing \"\{name}\"")
  }
}

///|
/// Requires a JSON string.
fn as_string(json : Json, context : String) -> String raise PortfolioError {
  match json {
    String(value) => value
    _ => raise InvalidConfig("\{context}: expected a string")
  }
}

///|
/// Reads a required string field.
fn string_field(
  json : Json,
  name : String,
  context : String,
) -> String raise PortfolioError {
  as_string(field(json, name, context), "\{context}.\{name}")
}

///|
/// Reads a required integer field.
fn int_field(
  json : Json,
  name : String,
  context : String,
) -> Int raise PortfolioError {
  match field(json, name, context) {
    Number(value, ..) => value.to_int()
    _ => raise InvalidConfig("\{context}.\{name}: expected a number")
  }
}

///|
/// Reads a required array field.
fn array_field(
  json : Json,
  name : String,
  context : String,
) -> Array[Json] raise PortfolioError {
  match field(json, name, context) {
    Array(items) => items
    _ => raise InvalidConfig("\{context}.\{name}: expected an array")
  }
}

///|
/// Reads a required project slug.
fn slug_field(
  json : Json,
  name : String,
  context : String,
) -> ProjectSlug raise PortfolioError {
  let slug = string_field(json, name, context)
  match ProjectSlug::from_slug(slug) {
    Some(value) => value
    None =>
      raise InvalidConfig(
        "\{context}.\{name}: unknown project slug \"\{slug}\"",
      )
  }
}

///|
/// Reads a required accent name.
fn accent_field(
  json : Json,
  name : String,
  context : String,
) -> Accent raise PortfolioError {
  let accent = string_field(json, name, context)
  match Accent::from_name(accent) {
    Some(value) => value
    None =>
      raise InvalidConfig("\{context}.\{name}: unknown accent \"\{accent}\"")
  }
}

///|
/// Reads one project entry.
fn parse_project(entry : Json) -> Project raise PortfolioError {
  let context = "site.json.projects[]"
  let screenshot = field(entry, "screenshot", context)
  {
    slug: slug_field(entry, "slug", context),
    title: string_field(entry, "title", context),
    period: string_field(entry, "period", context),
    role: string_field(entry, "role", context),
    lede: string_field(entry, "lede", context),
    accent: accent_field(entry, "accent", context),
    links: array_field(entry, "links", context).map(link => {
      label: string_field(link, "label", context),
      href: string_field(link, "href", context),
    }),
    screenshot: {
      src: string_field(screenshot, "src", context),
      webp_src: string_field(screenshot, "webpSrc", context),
      href: string_field(screenshot, "href", context),
      width: int_field(screenshot, "width", context),
      height: int_field(screenshot, "height", context),
      alt: string_field(screenshot, "alt", context),
      caption: string_field(screenshot, "caption", context),
    },
    contributions: array_field(entry, "contributions", context).map(contribution => {
      title: string_field(contribution, "title", context),
      detail: string_field(contribution, "detail", context),
    }),
  }
}

///|
/// Reads `site.json` into the typed site model.
pub fn Site::from_json_text(text : String) -> Site raise PortfolioError {
  let root = parse_json(text, "site.json")
  let site = field(root, "site", "site.json")
  let recognition = field(root, "recognition", "site.json")
  {
    name: string_field(site, "name", "site.json.site"),
    role: string_field(site, "role", "site.json.site"),
    url: string_field(site, "url", "site.json.site"),
    social_image: string_field(site, "socialImage", "site.json.site"),
    email: string_field(site, "email", "site.json.site"),
    github: string_field(site, "github", "site.json.site"),
    resume_pdf: string_field(site, "resume", "site.json.site"),
    description: string_field(site, "description", "site.json.site"),
    projects: array_field(root, "projects", "site.json").map(parse_project),
    recognition: {
      headline: string_field(recognition, "headline", "site.json.recognition"),
      supporting_proof: array_field(
        recognition, "supportingProof", "site.json.recognition",
      ).map(proof => {
        label: string_field(proof, "label", "site.json.recognition"),
        source: string_field(proof, "source", "site.json.recognition"),
      }),
    },
  }
}

///|
/// Looks up a project by slug.
pub fn Site::project(self : Site, slug : ProjectSlug) -> Project? {
  for project in self.projects {
    if project.slug.slug() == slug.slug() {
      return Some(project)
    }
  }
  None
}

///|
/// Reads one experience entry.
fn parse_experience(entry : Json) -> Experience raise PortfolioError {
  let context = "resume.json.experience[]"
  {
    company: string_field(entry, "company", context),
    role: string_field(entry, "role", context),
    period: string_field(entry, "period", context),
    bullets: array_field(entry, "bullets", context).map(bullet => {
      as_string(bullet, context)
    }),
  }
}

///|
/// Reads `resume.json` into the typed resume model.
pub fn Resume::from_json_text(text : String) -> Resume raise PortfolioError {
  let root = parse_json(text, "resume.json")
  let recognition = field(root, "recognition", "resume.json")
  let education = field(root, "education", "resume.json")
  {
    name: string_field(root, "name", "resume.json"),
    title: string_field(root, "title", "resume.json"),
    location: string_field(root, "location", "resume.json"),
    email: string_field(root, "email", "resume.json"),
    website: string_field(root, "website", "resume.json"),
    profile: string_field(root, "profile", "resume.json"),
    experience: array_field(root, "experience", "resume.json").map(
      parse_experience,
    ),
    skills: array_field(root, "skills", "resume.json").map(skill => {
      label: string_field(skill, "label", "resume.json.skills"),
      items: string_field(skill, "items", "resume.json.skills"),
    }),
    recognition: {
      title: string_field(recognition, "title", "resume.json.recognition"),
      detail: string_field(recognition, "detail", "resume.json.recognition"),
    },
    education: {
      school: string_field(education, "school", "resume.json.education"),
      detail: string_field(education, "detail", "resume.json.education"),
    },
  }
}
