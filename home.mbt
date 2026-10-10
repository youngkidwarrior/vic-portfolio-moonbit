///|
/// The four ink paths of the hero convergence artwork. Each entry is the band
/// name used by the stylesheet and the source-image path carried over from the
/// original component.
fn hero_art_bands() -> Array[(String, String)] {
  [
    ("blue", "M0 0H1000V527C900 527 875 468 710 452H0Z"),
    (
      "red", "M0 452H710C875 468 900 527 1000 527V540C810 540 805 596 620 619H0Z",
    ),
    (
      "yellow", "M0 619H620C805 596 810 540 1000 540V552C804 552 775 728 586 714H0Z",
    ),
    ("green", "M0 714H586C775 728 804 552 1000 552V992H0Z"),
  ]
}

///|
/// The hero convergence artwork: one hidden rest layer, four masked bands that
/// converge, and the hub. Decorative only, so it is hidden from assistive
/// technology.
fn hero_art() -> String {
  let poster = "/images/art/hero-poster.webp"
  let defs = StringBuilder()
  let bands = StringBuilder()
  for band in hero_art_bands() {
    let ink = band.0
    let shape = band.1
    let clip =
      $|<clipPath id="hero-art-\{ink}"><path d="\{shape}"/></clipPath>
    defs.write_string(clip)
    let group =
      $|<g data-art-layer class="convergence-band convergence-\{ink}"><image clip-path="url(#hero-art-\{ink})" href="\{poster}" width="1586" height="992"/></g>
    bands.write_string(group)
  }
  let clip_defs = defs.to_string()
  let band_layers = bands.to_string()
  let html =
    $|<svg class="hero-art-media hero-convergence" viewBox="0 150 1586 760" aria-hidden="true" focusable="false">
    $|<defs>\{clip_defs}<clipPath id="hero-art-hub"><path d="M1000 0H1586V992H1000Z"/></clipPath></defs>
    $|<image data-art-layer class="convergence-rest" href="\{poster}" width="1586" height="992"/>
    $|\{band_layers}
    $|<image class="convergence-hub" clip-path="url(#hero-art-hub)" href="\{poster}" width="1586" height="992"/>
    $|</svg>
  html
}

///|
/// The hero: reading copy, the portrait with its ink frame, and the convergence
/// artwork behind both.
fn home_hero(site : Site) -> String {
  let html =
    $|<section class="hero page-frame" id="about" data-pointer="hero">
    $|<div class="hero-copy">
    $|<p class="mono-label" data-hero-line>About</p>
    $|<h1 data-hero-line>\{esc(site.name)}</h1>
    $|<p class="hero-role" data-hero-line>\{esc(with_period(site.role))}</p>
    $|<p class="hero-subhead" data-hero-line>I’ve spent the last eight years building across the stack, turning ambitious ideas into products people can actually use.</p>
    $|<div class="hero-actions" data-hero-line>
    $|<a class="button button-primary" href="/resume">View résumé \{icon_arrow_up_right()}</a>
    $|<a class="button button-secondary" href="/#work">See highlights \{icon_arrow_down_right()}</a>
    $|</div>
    $|</div>
    $|<figure class="portrait-frame hero-portrait">
    $|<span class="hero-portrait-rule" data-hero-rule aria-hidden="true"></span>
    $|<div class="portrait-stage">
    $|<span class="portrait-ink portrait-ink-blue" aria-hidden="true"></span>
    $|<span class="portrait-ink portrait-ink-red" aria-hidden="true"></span>
    $|<img src="/images/victor-portrait.webp" alt="Portrait of Victor Ginelli" width="800" height="786" fetchpriority="high" decoding="async">
    $|</div>
    $|<figcaption>\{esc(site.name)}</figcaption>
    $|</figure>
    $|<div class="hero-art-scene" data-artwork="hero">
    $|<div class="hero-art-plane">\{hero_art()}</div>
    $|</div>
    $|</section>
  html
}

///|
/// The three decorative slices of a project's poster artwork.
fn project_art(project : Project) -> String {
  let slug = project.slug.slug()
  let poster = "/images/art/\{slug}-poster.webp"
  let slices = StringBuilder()
  for part in ["one", "two", "three"] {
    let slice =
      $|<div class="project-art-slice project-art-\{part}" data-art-layer><img data-art-media src="\{poster}" alt="" width="1120" height="1400" loading="lazy" decoding="async" draggable="false"></div>
    slices.write_string(slice)
  }
  let slice_layers = slices.to_string()
  let html =
    $|<div class="project-art project-art-\{slug}" data-artwork="\{slug}">
    $|<div class="project-art-window" aria-hidden="true">
    $|<div class="project-art-pointer">
    $|\{slice_layers}
    $|</div>
    $|</div>
    $|</div>
  html
}

///|
/// The contribution labels shown as a scope-of-work list on a project row.
fn contribution_titles(project : Project) -> String {
  let out = StringBuilder()
  for contribution in project.contributions {
    let item =
      $|<li>\{esc(contribution.title)}</li>
    emit(out, item)
  }
  out.to_string()
}

///|
/// One project row: rule, screenshot with its artwork, and the reading copy.
fn project_row(project : Project) -> String {
  let details_href = "/work/\{project.slug.slug()}"
  let scope_label = "\{project.title} scope of work"
  let visit_label = "Visit the website shown for \{project.title}"
  let html =
    $|<div class="project-row project-\{project.accent.name()}">
    $|<span aria-hidden="true" class="project-rule"></span>
    $|<article class="simple-project" data-composition="project-showcase" data-pointer="project">
    $|<div class="reveal-motion project-visual" data-reveal>
    $|<figure class="project-screenshot">
    $|<span aria-hidden="true" class="project-transition-frame"></span>
    $|<div class="project-media">
    $|\{project_art(project)}
    $|<a class="project-image-link" href="\{esc(project.screenshot.href)}" target="_blank" rel="noreferrer" aria-label="\{esc(visit_label)}">
    $|<img src="\{esc(project.screenshot.webp_src)}" alt="\{esc(project.screenshot.alt)}" width="\{project.screenshot.width}" height="\{project.screenshot.height}" loading="lazy" decoding="async">
    $|</a>
    $|</div>
    $|<figcaption>\{esc(project.screenshot.caption)}</figcaption>
    $|</figure>
    $|</div>
    $|<div class="reveal-motion project-copy" data-reveal>
    $|<p class="mono-label">\{esc(project.period)} / \{esc(project.role)}</p>
    $|<h3>\{esc(project.title)}</h3>
    $|<p class="project-lede">\{esc(project.lede)}</p>
    $|<ul class="project-contributions" aria-label="\{esc(scope_label)}">
    $|\{contribution_titles(project)}
    $|</ul>
    $|<div class="simple-project-actions">
    $|<a class="text-link" href="\{details_href}">Project details \{icon_arrow_up_right()}</a>
    $|</div>
    $|</div>
    $|</article>
    $|</div>
  html
}

///|
/// The highlights section: every project row of the site in content order.
fn home_work(site : Site) -> String {
  let rows = StringBuilder()
  for project in site.projects {
    emit(rows, project_row(project))
  }
  let project_rows = rows.to_string()
  let html =
    $|<section class="work-section page-frame" id="work">
    $|<div class="reveal-motion section-intro" data-reveal>
    $|<h2>My recent highlights</h2>
    $|</div>
    $|<div class="project-list">
    $|\{project_rows}
    $|</div>
    $|</section>
  html
}

///|
/// The first supporting proof of the recognition block.
fn first_proof(recognition : Recognition) -> Proof raise PortfolioError {
  match recognition.supporting_proof {
    [proof, ..] => proof
    [] =>
      raise InvalidConfig(
        "site.json.recognition.supportingProof: expected at least one proof",
      )
  }
}

///|
/// The recognition section, with the headline from content and the copy and
/// proof link carried over from the original home page.
fn recognition_section(
  recognition : Recognition,
) -> String raise PortfolioError {
  let proof = first_proof(recognition)
  let html =
    $|<section class="recognition-section recognition-compact page-frame">
    $|<div class="reveal-motion recognition-copy" data-reveal>
    $|<p class="mono-label">Recognition</p>
    $|<h2>\{esc(recognition.headline)}</h2>
    $|<p>Built NFT Request, a hackathon prototype that let people browse NFTs held by an Aragon DAO, make token-backed offers, and complete approved exchanges through the DAO’s existing governance process.</p>
    $|<a class="text-link" href="\{esc(proof.source)}" target="_blank" rel="noreferrer">View the project \{icon_arrow_up_right()}</a>
    $|</div>
    $|</section>
  html
}

///|
/// The home route: hero, highlights, and recognition.
fn home_page(site : Site) -> String raise PortfolioError {
  let html =
    $|\{home_hero(site)}
    $|\{home_work(site)}
    $|\{recognition_section(site.recognition)}
  html
}
