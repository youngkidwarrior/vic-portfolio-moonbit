const escapeAttribute = value => String(value).replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

const devStyles = ['fonts', 'app', 'hero-art', 'project-art', 'artwork-playback', 'port']
  .map(name => `<link rel="stylesheet" href="/styles/${name}.css">`).join('\n');

export function documentHtml({ body, metadata, scripts = '<script type="module" src="/host.js"></script>', styles = devStyles }) {
  const title = escapeAttribute(metadata.title);
  const description = escapeAttribute(metadata.description);
  const canonical = escapeAttribute(metadata.canonical);
  const image = escapeAttribute(metadata.image);
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="generator" content="MoonBit portfolio">
<title>${title}</title><meta name="description" content="${description}">
<link rel="canonical" href="${canonical}"><link rel="icon" href="/favicon.svg" type="image/svg+xml">
<meta property="og:type" content="website"><meta property="og:title" content="${title}">
<meta property="og:description" content="${description}"><meta property="og:url" content="${canonical}">
<meta property="og:image" content="${image}"><meta property="og:image:secure_url" content="${image}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:image" content="${image}">
<link rel="preload" href="/fonts/space-grotesk-latin-wght-normal.woff2" as="font" type="font/woff2" crossorigin>
${styles}
<script>try { const theme = localStorage.getItem('portfolio-theme'); document.documentElement.dataset.theme = theme === 'dark' || theme === 'light' ? theme : matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'; } catch { document.documentElement.dataset.theme = 'light'; }</script>
${scripts}
</head>
<body><div id="app">${body}</div></body>
</html>`;
}
