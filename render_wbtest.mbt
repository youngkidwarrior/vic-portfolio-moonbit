///|
test "path normalization drops query, fragment, and stray slashes" {
  assert_eq(normalize_path("/"), "/")
  assert_eq(normalize_path(""), "/")
  assert_eq(normalize_path("///"), "/")
  assert_eq(normalize_path("/resume/"), "/resume")
  assert_eq(normalize_path("/resume/?utm=x"), "/resume")
  assert_eq(normalize_path("/work//send#top"), "/work/send")
  assert_eq(normalize_path("work/send"), "/work/send")
  assert_eq(normalize_path("/work/send?q=1#top"), "/work/send")
}

///|
test "known routes report 200 and unknown routes report 404" {
  for
    path in [
      "/", "", "/resume", "/resume/", "/resume?x=1", "/work/send", "/work/send/",
      "/work/shenanigan", "/work/brightid", "/work/open-source#top",
    ] {
    assert_eq(route_status(path), 200)
  }
  for slug in ProjectSlug::all() {
    assert_eq(route_status("/work/\{slug.slug()}"), 200)
  }
  for
    path in [
      "/unknown", "/work", "/work/nope", "/work/send/extra", "/RESUME", "/about",
    ] {
    assert_eq(route_status(path), 404)
  }
}

///|
test "theme and menu toggles follow the stored state" {
  assert_eq(toggle_theme("light"), "dark")
  assert_eq(toggle_theme("dark"), "light")
  assert_eq(toggle_theme(""), "dark")
  assert_eq(toggle_theme("sepia"), "dark")
  assert_eq(toggle_menu(false), true)
  assert_eq(toggle_menu(true), false)
}

///|
test "metadata describes every route" {
  let site = fixture_site_json()
  let resume_content = fixture_resume_json()
  assert_metadata(
    page_metadata("/", site, resume_content),
    "Victor Ginelli | Founder and full-stack product engineer",
    "https://victor.she.energy/",
    "https://victor.she.energy/og.png",
  )
  assert_metadata(
    page_metadata("/resume/", site, resume_content),
    "Resume | Victor Ginelli",
    "https://victor.she.energy/resume",
    "https://victor.she.energy/og.png",
  )
  assert_eq(
    metadata_description(page_metadata("/resume", site, resume_content)),
    Resume::from_json_text(resume_content).profile,
  )
  assert_metadata(
    page_metadata("/work/send/?utm=x", site, resume_content),
    "Send | Victor Ginelli",
    "https://victor.she.energy/work/send",
    "https://victor.she.energy/images/work/send.jpg",
  )
  assert_metadata(
    page_metadata("/nope", site, resume_content),
    "Page not found | Victor Ginelli",
    "https://victor.she.energy/nope",
    "https://victor.she.energy/og.png",
  )
}

///|
test "home page renders the hero, highlights, and recognition" {
  let site_json = fixture_site_json()
  let site = Site::from_json_text(site_json)
  let resume_json = fixture_resume_json()
  let html = render_page("/", site_json, resume_json, 2026)
  assert_true(html.has_prefix("<div class=\"site-shell\">"))
  assert_true(html.contains("<header class=\"site-header\">"))
  assert_true(
    html.contains(
      "<a class=\"skip-link\" href=\"#main-content\">Skip to content</a>",
    ),
  )
  assert_true(
    html.contains(
      "<nav id=\"primary-navigation\" class=\"primary-nav\" aria-label=\"Primary\">",
    ),
  )
  assert_true(html.contains("<a href=\"/#work\">Work</a>"))
  assert_true(html.contains("<a href=\"/#about\">About</a>"))
  assert_true(html.contains("<a href=\"/resume\">Resume</a>"))
  assert_true(html.contains("href=\"mailto:victor@she.energy\">Contact</a>"))
  assert_true(
    html.contains(
      "<button class=\"icon-button\" type=\"button\" data-action=\"theme\" aria-label=\"Switch to dark theme\">",
    ),
  )
  assert_true(
    html.contains(
      "data-action=\"menu\" aria-controls=\"primary-navigation\" aria-expanded=\"false\" aria-label=\"Toggle navigation\">",
    ),
  )
  assert_true(html.contains("<main id=\"main-content\" tabindex=\"-1\">"))
  assert_true(
    html.contains(
      "<section class=\"hero page-frame\" id=\"about\" data-pointer=\"hero\">",
    ),
  )
  assert_true(html.contains("<h1 data-hero-line>Victor Ginelli</h1>"))
  assert_true(
    html.contains(
      "<p class=\"hero-role\" data-hero-line>Founder and full-stack product engineer.</p>",
    ),
  )
  assert_true(
    html.contains(
      "I’ve spent the last eight years building across the stack, turning ambitious ideas into products people can actually use.",
    ),
  )
  assert_true(
    html.contains(
      "<a class=\"button button-primary\" href=\"/resume\">View résumé",
    ),
  )
  assert_true(
    html.contains(
      "<a class=\"button button-secondary\" href=\"/#work\">See highlights",
    ),
  )
  assert_true(
    html.contains(
      "<span class=\"hero-portrait-rule\" data-hero-rule aria-hidden=\"true\"></span>",
    ),
  )
  assert_true(
    html.contains(
      "<span class=\"portrait-ink portrait-ink-blue\" aria-hidden=\"true\"></span>",
    ),
  )
  assert_true(
    html.contains(
      "<span class=\"portrait-ink portrait-ink-red\" aria-hidden=\"true\"></span>",
    ),
  )
  assert_true(
    html.contains(
      "src=\"/images/victor-portrait.webp\" alt=\"Portrait of Victor Ginelli\" width=\"800\" height=\"786\"",
    ),
  )
  assert_true(html.contains("<figcaption>Victor Ginelli</figcaption>"))
  assert_true(
    html.contains("<div class=\"hero-art-scene\" data-artwork=\"hero\">"),
  )
  assert_true(
    html.contains(
      "<svg class=\"hero-art-media hero-convergence\" viewBox=\"0 150 1586 760\"",
    ),
  )
  assert_true(html.contains("class=\"convergence-band convergence-blue\""))
  assert_true(html.contains("class=\"convergence-band convergence-green\""))
  assert_true(
    html.contains("<section class=\"work-section page-frame\" id=\"work\">"),
  )
  assert_true(html.contains("<h2>My recent highlights</h2>"))
  assert_true(html.contains("<div class=\"project-list\">"))
  assert_true(
    html.contains(
      "data-composition=\"project-showcase\" data-pointer=\"project\">",
    ),
  )
  assert_true(
    html.contains("class=\"reveal-motion project-visual\" data-reveal>"),
  )
  assert_true(
    html.contains("class=\"reveal-motion project-copy\" data-reveal>"),
  )
  for project in site.projects {
    let slug = project.slug.slug()
    assert_true(
      html.contains(
        "<div class=\"project-row project-\{project.accent.name()}\">",
      ),
    )
    assert_true(
      html.contains(
        "class=\"project-art project-art-\{slug}\" data-artwork=\"\{slug}\">",
      ),
    )
    assert_true(html.contains("/images/art/\{slug}-poster.webp"))
    assert_true(
      html.contains(
        "<img src=\"\{esc(project.screenshot.webp_src)}\" alt=\"\{esc(project.screenshot.alt)}\" width=\"\{project.screenshot.width}\" height=\"\{project.screenshot.height}\"",
      ),
    )
    assert_true(
      html.contains(
        "<p class=\"mono-label\">\{esc(project.period)} / \{esc(project.role)}</p>",
      ),
    )
    assert_true(html.contains("<h3>\{esc(project.title)}</h3>"))
    assert_true(
      html.contains("<p class=\"project-lede\">\{esc(project.lede)}</p>"),
    )
    assert_true(
      html.contains(
        "<a class=\"text-link\" href=\"/work/\{slug}\">Project details",
      ),
    )
    assert_true(
      html.contains("aria-label=\"\{esc(project.title)} scope of work\""),
    )
    for contribution in project.contributions {
      assert_true(html.contains("<li>\{esc(contribution.title)}</li>"))
    }
  }
  assert_true(html.contains("<h2>Winner, Aragon Hack for Freedom</h2>"))
  assert_true(
    html.contains(
      "href=\"https://hackmd.io/@HADkohMGSyy8wLqA3Vdj6w/ryxO3Aqew\" target=\"_blank\" rel=\"noreferrer\">View the project",
    ),
  )
  assert_true(
    html.contains(
      "<p class=\"footer-callout\">Building something ambitious?</p>",
    ),
  )
  assert_true(html.contains("<span>© 2026 Victor Ginelli</span>"))
  assert_true(
    html.contains(
      "<a href=\"https://github.com/youngkidwarrior\" target=\"_blank\" rel=\"noreferrer\">GitHub</a>",
    ),
  )
  assert_true(
    html.contains("<a href=\"/victor-ginelli-resume.pdf\">PDF resume</a>"),
  )
}

///|
test "every case study keeps its contributions, links, and screenshot" {
  let site_json = fixture_site_json()
  let site = Site::from_json_text(site_json)
  let resume_json = fixture_resume_json()
  for project in site.projects {
    let slug = project.slug.slug()
    let html = render_page("/work/\{slug}", site_json, resume_json, 2026)
    assert_true(
      html.contains(
        "<article class=\"case-study project-\{project.accent.name()}\">",
      ),
    )
    assert_true(html.contains("<header class=\"case-hero page-frame\">"))
    assert_true(
      html.contains(
        "<a class=\"back-link\" href=\"/#work\" data-action=\"all-work\">",
      ),
    )
    assert_true(html.contains("<div class=\"case-title-grid\">"))
    assert_true(html.contains("<h1>\{esc(project.title)}</h1>"))
    assert_true(
      html.contains("<p class=\"case-lede\">\{esc(project.lede)}</p>"),
    )
    assert_true(html.contains("<figure class=\"case-screenshot\">"))
    assert_true(html.contains("<h2>What Victor built</h2>"))
    assert_true(html.contains("<section class=\"external-links page-frame\">"))
    assert_true(html.contains("<h2>Project links</h2>"))
    assert_eq(count_of(html, "<li><h3>"), project.contributions.length())
    for contribution in project.contributions {
      assert_true(
        html.contains(
          "<h3>\{esc(contribution.title)}</h3><p>\{esc(contribution.detail)}</p>",
        ),
      )
    }
    for link in project.links {
      assert_true(
        html.contains(
          "<a href=\"\{esc(link.href)}\" target=\"_blank\" rel=\"noreferrer\">\{esc(link.label)} ",
        ),
      )
    }
    assert_true(!html.contains("project-art-\{slug}"))
  }
}

///|
test "resume keeps every role, bullet, skill, and contact detail" {
  let site_json = fixture_site_json()
  let resume_json = fixture_resume_json()
  let resume_content = Resume::from_json_text(resume_json)
  let html = render_page("/resume", site_json, resume_json, 2026)
  assert_true(html.contains("<article class=\"resume-page page-frame\">"))
  assert_true(html.contains("<h1>\{esc(resume_content.name)}</h1>"))
  assert_true(html.contains("<p>\{esc(resume_content.title)}</p>"))
  assert_true(html.contains("<h2>Profile</h2>"))
  assert_true(html.contains("<p>\{esc(resume_content.profile)}</p>"))
  assert_true(html.contains("<h2>Experience</h2>"))
  assert_true(
    html.contains(
      "<a class=\"button button-primary\" href=\"/victor-ginelli-resume.pdf\" download=\"victor-ginelli-resume.pdf\">Download PDF",
    ),
  )
  assert_eq(
    count_of(html, "class=\"resume-role\">"),
    resume_content.experience.length(),
  )
  for role in resume_content.experience {
    assert_true(
      html.contains(
        "<h3>\{esc(role.company)}</h3><p>\{esc(role.role)}</p></div><time>\{esc(role.period)}</time>",
      ),
    )
    for bullet in role.bullets {
      assert_true(html.contains("<li>\{esc(bullet)}</li>"))
    }
  }
  assert_true(html.contains("<h2>Technical range</h2>"))
  for skill in resume_content.skills {
    assert_true(
      html.contains(
        "<p><strong>\{esc(skill.label)}</strong><br>\{esc(skill.items)}</p>",
      ),
    )
  }
  assert_true(html.contains("<h2>Recognition</h2>"))
  assert_true(html.contains("<h2>Education</h2>"))
  assert_true(
    html.contains(
      "<strong>\{esc(resume_content.education.school)}</strong><br>\{esc(resume_content.education.detail)}</p>",
    ),
  )
  assert_true(html.contains("<h2>Connect</h2>"))
  assert_true(html.contains("<p>\{esc(resume_content.location)}</p>"))
  assert_true(
    html.contains(
      "href=\"mailto:\{esc(resume_content.email)}\">\{esc(resume_content.email)} ",
    ),
  )
  assert_true(
    html.contains(
      "href=\"https://github.com/youngkidwarrior\" target=\"_blank\" rel=\"noreferrer\">GitHub ",
    ),
  )
  assert_true(!html.contains("phone"))
}

///|
test "unknown routes render a 404 page whose echoed path is escaped" {
  let hostile_path = "/<script>alert(1)</script>"
  let html = render_page(
    hostile_path,
    fixture_site_json(),
    fixture_resume_json(),
    2026,
  )
  assert_true(html.contains("<article class=\"error-page\">"))
  assert_true(html.contains("<p class=\"mono-label\">404 / Off course</p>"))
  assert_true(html.contains("<h1>The route moved. The work did not.</h1>"))
  assert_true(html.contains("<a class=\"text-link\" href=\"/\">Return home "))
  assert_true(html.contains("&lt;script&gt;alert(1)&lt;/script&gt;"))
  assert_true(!html.contains("<script>alert(1)</script>"))
}

///|
test "content markup, quotes, and ampersands are escaped" {
  let site_json = fixture_hostile_site_json()
  let resume_json = fixture_resume_json()
  let html = render_page("/", site_json, resume_json, 2026)
  let case_html = render_page("/work/send", site_json, resume_json, 2026)
  assert_true(html.contains("&lt;script&gt;alert(1)&lt;/script&gt;"))
  assert_true(!html.contains("</h1><script>alert(1)</script>"))
  assert_true(
    html.contains("Rates &amp;&amp;&amp;&amp; terms &lt;b&gt;bold&lt;/b&gt;"),
  )
  assert_true(html.contains("<li>&lt;b&gt;bold&lt;/b&gt;</li>"))
  assert_true(case_html.contains("<h3>&lt;b&gt;bold&lt;/b&gt;</h3>"))
  assert_true(
    case_html.contains(
      "&quot;double quotes&quot; &amp; &lt;em&gt;italics&lt;/em&gt;.",
    ),
  )
  assert_true(
    case_html.contains(
      "href=\"https://send.it/?a=b&amp;c=d\" target=\"_blank\" rel=\"noreferrer\">Visit &lt;Send&gt; ",
    ),
  )
  assert_true(
    html.contains("alt=\"Send &lt;shot&gt;\" width=\"1120\" height=\"630\""),
  )
}

///|
test "invalid configuration raises instead of rendering" {
  let missing_keys : Site? = Some(Site::from_json_text("{ \"site\": {} }")) catch {
    InvalidConfig(_) => None
  }
  assert_true(missing_keys is None)
  let unknown_slug_json = fixture_hostile_site_json().replace_all(
    old="\"slug\": \"send\"",
    new="\"slug\": \"career\"",
  )
  let unknown_slug : Site? = Some(
    Site::from_json_text(unknown_slug_json.to_string()),
  ) catch {
    InvalidConfig(_) => None
  }
  assert_true(unknown_slug is None)
  let unknown_accent_json = fixture_hostile_site_json().replace_all(
    old="\"accent\": \"cobalt\"",
    new="\"accent\": \"plaid\"",
  )
  let unknown_accent : Site? = Some(
    Site::from_json_text(unknown_accent_json.to_string()),
  ) catch {
    InvalidConfig(_) => None
  }
  assert_true(unknown_accent is None)
  let missing_project : String? = Some(
    render_page(
      "/work/brightid",
      fixture_hostile_site_json(),
      fixture_resume_json(),
      2026,
    ),
  ) catch {
    InvalidConfig(_) => None
  }
  assert_true(missing_project is None)
}

///|
test "renderer reuse preserves routes metadata and request years" {
  let site = fixture_site_json()
  let resume_content = fixture_resume_json()
  let renderer = Renderer::new(site, resume_content)
  for year in [2026, 2027, 2026] {
    for
      path in [
        "/", "/resume/", "/work/send", "/work/shenanigan", "/work/brightid", "/work/open-source",
        "/unknown",
      ] {
      assert_eq(
        renderer.render_page(path, year),
        render_page(path, site, resume_content, year),
      )
      assert_eq(
        renderer.page_metadata(path),
        page_metadata(path, site, resume_content),
      )
      assert_true(
        renderer.render_page(path, year).contains("© \{year} Victor Ginelli"),
      )
    }
  }
}

///|
test "renderer contexts isolate changed inputs and survive rejected content" {
  let site = fixture_site_json()
  let resume_content = fixture_resume_json()
  let first = Renderer::new(site, resume_content)
  let changed_site = site
    .replace_all(old="Victor Ginelli", new="Another Author")
    .to_string()
  let changed_resume = resume_content
    .replace_all(old="Victor Ginelli", new="Resume Author")
    .to_string()
  let second = Renderer::new(changed_site, changed_resume)
  assert_true(second.render_page("/", 2027).contains("Another Author"))
  assert_true(second.render_page("/resume", 2027).contains("Resume Author"))
  assert_true(first.render_page("/", 2026).contains("Victor Ginelli"))
  assert_true(!first.render_page("/", 2026).contains("Another Author"))
  for
    (bad_site, bad_resume) in [
      ("{", resume_content),
      (site, "{"),
      ("{}", resume_content),
      (site, "{}"),
    ] {
    let rejected : Renderer? = Some(Renderer::new(bad_site, bad_resume)) catch {
      InvalidConfig(_) => None
    }
    assert_true(rejected is None)
    assert_eq(
      first.page_metadata("/"),
      page_metadata("/", site, resume_content),
    )
  }
  let recovered = Renderer::new(site, resume_content)
  assert_eq(
    recovered.render_page("/resume", 2028),
    first.render_page("/resume", 2028),
  )
}
