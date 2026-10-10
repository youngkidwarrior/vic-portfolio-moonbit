///|
/// Every role on the resume, with its full bullet list.
fn resume_roles(resume_content : Resume) -> String {
  let out = StringBuilder()
  for role in resume_content.experience {
    let bullets = StringBuilder()
    for bullet in role.bullets {
      let item =
        $|<li>\{esc(bullet)}</li>
      emit(bullets, item)
    }
    let html =
      $|<article class="resume-role">
      $|<header><div><h3>\{esc(role.company)}</h3><p>\{esc(role.role)}</p></div><time>\{esc(role.period)}</time></header>
      $|<ul>
      $|\{bullets.to_string()}
      $|</ul>
      $|</article>
    emit(out, html)
  }
  out.to_string()
}

///|
/// The technical range entries.
fn resume_skills(resume_content : Resume) -> String {
  let out = StringBuilder()
  for skill in resume_content.skills {
    let item =
      $|<p><strong>\{esc(skill.label)}</strong><br>\{esc(skill.items)}</p>
    emit(out, item)
  }
  out.to_string()
}

///|
/// The resume route: header with the PDF download, profile, every role, and the
/// technical range, recognition, education, and contact columns.
fn resume_page(site : Site, resume_content : Resume) -> String {
  let html =
    $|<article class="resume-page page-frame">
    $|<header class="resume-header">
    $|<div>
    $|<h1>\{esc(resume_content.name)}</h1>
    $|<p>\{esc(resume_content.title)}</p>
    $|</div>
    $|<a class="button button-primary" href="\{esc(site.resume_pdf)}" download="victor-ginelli-resume.pdf">Download PDF \{icon_arrow_down()}</a>
    $|</header>
    $|<section class="resume-summary">
    $|<h2>Profile</h2>
    $|<p>\{esc(resume_content.profile)}</p>
    $|</section>
    $|<section class="resume-experience">
    $|<h2>Experience</h2>
    $|\{resume_roles(resume_content)}
    $|</section>
    $|<section class="resume-columns">
    $|<div>
    $|<h2>Technical range</h2>
    $|\{resume_skills(resume_content)}
    $|</div>
    $|<div>
    $|<h2>Recognition</h2>
    $|<p><strong>\{esc(resume_content.recognition.title)}</strong><br>\{esc(resume_content.recognition.detail)}</p>
    $|<h2>Education</h2>
    $|<p><strong>\{esc(resume_content.education.school)}</strong><br>\{esc(resume_content.education.detail)}</p>
    $|<h2>Connect</h2>
    $|<p>\{esc(resume_content.location)}</p>
    $|<p><a class="text-link" href="mailto:\{esc(resume_content.email)}">\{esc(resume_content.email)} \{icon_arrow_up_right()}</a></p>
    $|<p><a class="text-link" href="\{esc(site.github)}" target="_blank" rel="noreferrer">GitHub \{icon_arrow_up_right()}</a></p>
    $|</div>
    $|</section>
    $|</article>
  html
}
