///|
/// Renders the unknown-route page.
///
/// The requested path is echoed escaped, so a hostile path cannot inject
/// markup, and the page always offers a way back to the home page.
fn not_found_page(path : String) -> String {
  let html =
    $|<article class="error-page">
    $|<p class="mono-label">404 / Off course</p>
    $|<h1>The route moved. The work did not.</h1>
    $|<p>Nothing is served at <code>\{esc(path)}</code> yet.</p>
    $|<a class="text-link" href="/">Return home \{icon_arrow_up_right()}</a>
    $|</article>
  html
}
