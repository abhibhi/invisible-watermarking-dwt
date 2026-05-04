// Template for the MATH 414-501 final report.
//
// Enforces the project spec's formatting requirements:
//   - 12 pt font
//   - 1.5 line spacing (approximated by leading: 1em, since Typst's default
//     leading of 0.65em corresponds to roughly single spacing)
//   - reasonable margins (1 in on all sides)
//   - single-column research-paper layout
//
// Usage:
//   #import "template.typ": report
//   #show: report.with(
//     title: "...",
//     authors: (...),
//     abstract: [...],
//     bibliography-file: "references.yml",
//   )

#let report(
  title: none,
  subtitle: none,
  authors: (),
  affiliation: none,
  date: none,
  abstract: none,
  keywords: (),
  bibliography-file: none,
  body,
) = {
  set document(title: title, author: authors.map(a => a.name).join(", "))

  set page(
    paper: "us-letter",
    margin: 1in,
    numbering: "1",
    number-align: center,
  )

  set text(
    font: "New Computer Modern",
    size: 12pt,
    lang: "en",
  )

  // Approximation of 1.5 line spacing: Typst's default leading is 0.65em
  // (single-spacing-ish), so 1em leading is roughly 1.5x.
  set par(
    leading: 1em,
    justify: true,
    first-line-indent: 1.5em,
  )

  set heading(numbering: "1.1")

  show heading.where(level: 1): it => {
    set text(size: 14pt, weight: "bold")
    set block(above: 1.5em, below: 0.8em)
    it
  }
  show heading.where(level: 2): it => {
    set text(size: 12pt, weight: "bold")
    set block(above: 1.2em, below: 0.6em)
    it
  }
  show heading.where(level: 3): it => {
    set text(size: 12pt, weight: "bold", style: "italic")
    set block(above: 1em, below: 0.4em)
    it
  }

  show figure.caption: it => {
    set text(size: 10pt)
    it
  }
  show figure: set block(breakable: true)

  set math.equation(numbering: "(1)")

  // ---------------- Title block ----------------
  align(center)[
    #block(text(weight: "bold", size: 18pt, title))
    #if subtitle != none {
      v(0.4em)
      block(text(size: 13pt, style: "italic", subtitle))
    }
    #v(1em)
    #grid(
      columns: authors.len(),
      column-gutter: 2em,
      row-gutter: 0.4em,
      ..authors.map(a => align(center, strong(text(size: 12pt, a.name)))),
      ..authors.map(a => align(
        center,
        if "email" in a { text(size: 10pt, raw(a.email)) },
      )),
    )
    #if affiliation != none {
      v(0.4em)
      block(text(size: 11pt, style: "italic", affiliation))
    }
    #if date != none {
      v(0.4em)
      block(text(size: 11pt, date))
    }
  ]

  v(1em)

  // ---------------- Abstract ----------------
  if abstract != none {
    block(
      width: 100%,
      inset: (x: 1.5em, y: 0.8em),
      stroke: (top: 0.5pt, bottom: 0.5pt),
    )[
      #align(center)[*Abstract*]
      #set par(leading: 0.85em, first-line-indent: 0pt)
      #set text(size: 11pt)
      #abstract
      #if keywords.len() > 0 [
        #v(0.5em)
        *Keywords —* #keywords.join("; ")
      ]
    ]
    v(0.8em)
  }

  // ---------------- Body ----------------
  body

  // ---------------- Bibliography ----------------
  if bibliography-file != none {
    pagebreak()
    bibliography(bibliography-file, title: "References", style: "ieee")
  }
}
