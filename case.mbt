///|
/// The contributions section of a case study: every entry with its full detail.
fn contribution_list(project : Project) -> String {
  let out = StringBuilder()
  for contribution in project.contributions {
    let item =
      $|<li><h3>\{esc(contribution.title)}</h3><p>\{esc(contribution.detail)}</p></li>
    emit(out, item)
  }
  out.to_string()
}

///|
/// The external links section of a case study.
fn project_links(project : Project) -> String {
  let out = StringBuilder()
  for link in project.links {
    let item =
      $|<a href="\{esc(link.href)}" target="_blank" rel="noreferrer">\{esc(link.label)} \{icon_arrow_up_right()}</a>
    emit(out, item)
  }
  out.to_string()
}

///|
/// A case study: title block, the authentic screenshot, the full contribution
/// list, and the project's external links. No decorative artwork on a detail
/// page.
fn case_page(project : Project) -> String {
  let visit_label = "Visit the website shown for \{project.title}"
  let html =
    $|<article class="case-study project-\{project.accent.name()}">
    $|<header class="case-hero page-frame">
    $|<a class="back-link" href="/#work" data-action="all-work">\{icon_arrow_left()} All work</a>
    $|<div class="case-title-grid">
    $|<div>
    $|<p class="mono-label">\{esc(project.period)} / \{esc(project.role)}</p>
    $|<h1>\{esc(project.title)}</h1>
    $|<p class="case-lede">\{esc(project.lede)}</p>
    $|</div>
    $|</div>
    $|<figure class="case-screenshot">
    $|<span aria-hidden="true" class="project-transition-frame"></span>
    $|<a class="project-image-link" href="\{esc(project.screenshot.href)}" target="_blank" rel="noreferrer" aria-label="\{esc(visit_label)}">
    $|<img src="\{esc(project.screenshot.webp_src)}" alt="\{esc(project.screenshot.alt)}" width="\{project.screenshot.width}" height="\{project.screenshot.height}" decoding="async">
    $|</a>
    $|<figcaption>\{esc(project.screenshot.caption)}</figcaption>
    $|</figure>
    $|</header>
    $|<section class="contribution-section page-frame">
    $|<header class="contribution-heading">
    $|<h2>What Victor built</h2>
    $|</header>
    $|<ul class="contribution-list">
    $|\{contribution_list(project)}
    $|</ul>
    $|</section>
    $|<section class="external-links page-frame">
    $|<h2>Project links</h2>
    $|<div>
    $|\{project_links(project)}
    $|</div>
    $|</section>
    $|</article>
  html
}
