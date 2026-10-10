///|
/// A derived fixture that mirrors `content/site.json`: the same keys, real
/// values for every field it keeps, and one entry per project slug so every
/// route and accent is exercised.
fn fixture_site_json() -> String {
  let text =
    #|{
    #|  "site": {
    #|    "name": "Victor Ginelli",
    #|    "role": "Founder and full-stack product engineer",
    #|    "url": "https://victor.she.energy",
    #|    "socialImage": "/og.png",
    #|    "email": "victor@she.energy",
    #|    "github": "https://github.com/youngkidwarrior",
    #|    "resume": "/victor-ginelli-resume.pdf",
    #|    "description": "Victor Ginelli is a founder and full-stack product engineer building payments, identity, mobile, blockchain, and community products."
    #|  },
    #|  "projects": [
    #|    {
    #|      "slug": "send",
    #|      "title": "Send",
    #|      "period": "2023 - 2026",
    #|      "role": "Senior full-stack engineer",
    #|      "lede": "Helped scale Send across web and mobile, supporting $53M+ in transfers, 70K+ passkeys, and 15 iOS releases.",
    #|      "links": [{ "label": "Visit Send", "href": "https://send.it" }],
    #|      "screenshot": {
    #|        "src": "/images/work/send.jpg",
    #|        "webpSrc": "/images/work/send.webp",
    #|        "href": "https://send.it",
    #|        "width": 1120,
    #|        "height": 630,
    #|        "alt": "Send website showing a customer using the mobile payments product",
    #|        "caption": "Send's consumer payments brand."
    #|      },
    #|      "contributions": [
    #|        { "title": "Virtual debit card", "detail": "Led the product from architecture through launch, connecting passkey ownership, identity checks, card issuance, funding, authentication, and card controls." },
    #|        { "title": "Community rewards", "detail": "Designed a gaming-resistant activity and token-distribution system that allocated 81M+ SEND." }
    #|      ],
    #|      "accent": "cobalt"
    #|    },
    #|    {
    #|      "slug": "shenanigan",
    #|      "title": "Shenanigan",
    #|      "period": "2018 - 2023",
    #|      "role": "Founder and technical lead",
    #|      "lede": "Founded Shenanigan to help athletes earn from their work while keeping control of their identity and assets.",
    #|      "links": [
    #|        { "label": "Visit Shenanigan", "href": "https://she.energy" },
    #|        { "label": "Visit PANTS", "href": "https://pants.energy" }
    #|      ],
    #|      "screenshot": {
    #|        "src": "/images/work/pants.jpg",
    #|        "webpSrc": "/images/work/pants.webp",
    #|        "href": "https://pants.energy",
    #|        "width": 720,
    #|        "height": 576,
    #|        "alt": "PANTS product page showing digital clothing available to buy",
    #|        "caption": "PANTS turned community energy into added runway."
    #|      },
    #|      "contributions": [
    #|        { "title": "Dripp and $PANTS", "detail": "Created Dripp, a cross-community rewards system where supporters staked $PRTCLE and earned redeemable $PANTS." }
    #|      ],
    #|      "accent": "red"
    #|    },
    #|    {
    #|      "slug": "brightid",
    #|      "title": "BrightID Bot",
    #|      "period": "2020 - 2023",
    #|      "role": "Project lead",
    #|      "lede": "Turned a weekend prototype into a service that verified 11,000+ people in one year.",
    #|      "links": [{ "label": "Visit BrightID Bot", "href": "https://bot.brightid.org" }],
    #|      "screenshot": {
    #|        "src": "/images/work/brightid-bot.jpg",
    #|        "webpSrc": "/images/work/brightid-bot.webp",
    #|        "href": "https://bot.brightid.org",
    #|        "width": 1120,
    #|        "height": 630,
    #|        "alt": "BrightID Bot dashboard for Discord community verification",
    #|        "caption": "A simple dashboard for community verification."
    #|      },
    #|      "contributions": [
    #|        { "title": "Verification at scale", "detail": "Led the service as it verified more than 11,000 people in one year." }
    #|      ],
    #|      "accent": "green"
    #|    },
    #|    {
    #|      "slug": "open-source",
    #|      "title": "Open source",
    #|      "period": "2018 - 2023",
    #|      "role": "Selected contributor",
    #|      "lede": "Shipped focused product improvements across four open-source ecosystems.",
    #|      "links": [
    #|        { "label": "SourceCred", "href": "https://sourcecred.io" },
    #|        { "label": "Honeyswap", "href": "https://honeyswap.org" }
    #|      ],
    #|      "screenshot": {
    #|        "src": "/images/work/open-source.jpg",
    #|        "webpSrc": "/images/work/open-source.webp",
    #|        "href": "https://github.com/youngkidwarrior",
    #|        "width": 1120,
    #|        "height": 630,
    #|        "alt": "Victor Ginelli's GitHub profile with pinned open-source projects",
    #|        "caption": "Public work across product and protocol ecosystems."
    #|      },
    #|      "contributions": [
    #|        { "title": "Colony", "detail": "Contributed to DAO payment logic spanning application and smart-contract work." }
    #|      ],
    #|      "accent": "yellow"
    #|    }
    #|  ],
    #|  "recognition": {
    #|    "headline": "Winner, Aragon Hack for Freedom",
    #|    "supportingProof": [
    #|      { "label": "NFT Request submission", "source": "https://hackmd.io/@HADkohMGSyy8wLqA3Vdj6w/ryxO3Aqew" },
    #|      { "label": "Submission branch comparison", "source": "https://github.com/youngkidwarrior/token-request-app/compare/master...hack-for-freedom-submission" }
    #|    ]
    #|  }
    #|}
  text
}

///|
/// A derived fixture that mirrors `content/resume.json` with two roles and two
/// technical-range entries.
fn fixture_resume_json() -> String {
  let text =
    #|{
    #|  "name": "Victor Ginelli",
    #|  "title": "Founder and full-stack product engineer",
    #|  "location": "Los Angeles area",
    #|  "email": "victor@she.energy",
    #|  "website": "victor.she.energy",
    #|  "profile": "Founder and full-stack product engineer with 8+ years building payments, identity, mobile, and community products. Has led teams and taken complex systems from concept to production.",
    #|  "experience": [
    #|    {
    #|      "company": "Send",
    #|      "role": "Senior full-stack engineer",
    #|      "period": "Dec 2023 - Aug 2026",
    #|      "bullets": [
    #|        "Led a passkey-secured virtual debit card from architecture through launch, spanning wallet ownership, identity checks, issuance, funding, authentication, lifecycle controls, webhooks, and durable workflows.",
    #|        "Designed activity scoring and token distribution that allocated 81M+ SEND, equal to 27% of the community allocation."
    #|      ]
    #|    },
    #|    {
    #|      "company": "BrightID Discord Bot",
    #|      "role": "Project lead",
    #|      "period": "2020 - 2023",
    #|      "bullets": [
    #|        "Took an identity-verification bot from hackathon prototype to a production service that verified 11,000+ people in one year."
    #|      ]
    #|    }
    #|  ],
    #|  "skills": [
    #|    { "label": "Languages", "items": "TypeScript, JavaScript, SQL, Solidity, Bash" },
    #|    { "label": "Web and mobile", "items": "React, React Native, Expo, Next.js, Tamagui, tRPC, Zod, TanStack Query" }
    #|  ],
    #|  "recognition": { "title": "Winner, Aragon Hack for Freedom", "detail": "Built NFT Request, a prototype for browsing DAO-held NFTs, making token-backed offers, and completing approved exchanges through Aragon governance." },
    #|  "education": { "school": "Claremont McKenna College", "detail": "Physics and Computer Science, 2018" }
    #|}
  text
}

///|
/// A one-project fixture whose text carries markup, quotes, and ampersands, so
/// escaping can be checked in text and attribute positions. It also doubles as
/// the fixture that lacks the other three projects.
fn fixture_hostile_site_json() -> String {
  let text =
    #|{
    #|  "site": {
    #|    "name": "Victor Ginelli",
    #|    "role": "Founder and full-stack product engineer",
    #|    "url": "https://victor.she.energy",
    #|    "socialImage": "/og.png",
    #|    "email": "victor@she.energy",
    #|    "github": "https://github.com/youngkidwarrior",
    #|    "resume": "/victor-ginelli-resume.pdf",
    #|    "description": "Hostile fixture."
    #|  },
    #|  "projects": [
    #|    {
    #|      "slug": "send",
    #|      "title": "Send</h1><script>alert(1)</script>",
    #|      "period": "2023 - 2026",
    #|      "role": "Senior full-stack engineer",
    #|      "lede": "Rates &&&& terms <b>bold</b>",
    #|      "links": [{ "label": "Visit <Send>", "href": "https://send.it/?a=b&c=d" }],
    #|      "screenshot": {
    #|        "src": "/images/work/send.jpg",
    #|        "webpSrc": "/images/work/send.webp",
    #|        "href": "https://send.it",
    #|        "width": 1120,
    #|        "height": 630,
    #|        "alt": "Send <shot>",
    #|        "caption": "Send's brand & mark."
    #|      },
    #|      "contributions": [
    #|        { "title": "<b>bold</b>", "detail": "Uses \"double quotes\" & <em>italics</em>." }
    #|      ],
    #|      "accent": "cobalt"
    #|    }
    #|  ],
    #|  "recognition": {
    #|    "headline": "Winner, Aragon Hack for Freedom",
    #|    "supportingProof": [
    #|      { "label": "NFT Request submission", "source": "https://hackmd.io/@HADkohMGSyy8wLqA3Vdj6w/ryxO3Aqew" }
    #|    ]
    #|  }
    #|}
  text
}

///|
/// Counts non-overlapping occurrences of `needle` in `text`.
fn count_of(text : String, needle : String) -> Int {
  text.split(needle).collect().length() - 1
}

///|
/// Reads the `description` out of serialized metadata.
fn metadata_description(text : String) -> String raise {
  let metadata : Json = @json.parse(text)
  guard metadata is { "description": String(description), .. } else {
    fail("metadata must carry a description")
  }
  description
}

///|
/// Checks the title, canonical URL, and social image of serialized metadata.
fn assert_metadata(
  text : String,
  title : String,
  canonical : String,
  image : String,
) -> Unit raise {
  let metadata : Json = @json.parse(text)
  guard metadata
    is {
      "title": String(actual_title),
      "description": String(description),
      "canonical": String(actual_canonical),
      "image": String(actual_image),
      ..
    } else {
    fail("metadata must carry title, description, canonical, and image")
  }
  assert_eq(actual_title, title)
  assert_eq(actual_canonical, canonical)
  assert_eq(actual_image, image)
  assert_true(description.length() > 0)
}
