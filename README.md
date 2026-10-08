# CV — LaTeX source

Two-page CV for a graduate electrical engineer, built with `pdflatex`.
The compiled output is [`CV_Satria_Hadiwijaya_2026_Q4.pdf`](CV_Satria_Hadiwijaya_2026_Q4.pdf).

## Layout

| File | Contents |
| --- | --- |
| `main.tex` | Document root and section order |
| `config.sty` | Page geometry, fonts, spacing, entry macros, PDF metadata |
| `title.tex` | Header block and profile paragraph |
| `education.tex` | Degrees, WAM/GPA, coursework |
| `professional_experience.tex` | Roles and leadership positions |
| `projects.tex` | Engineering projects |
| `skills.tex` | Technical skills |
| `certification.tex` | Certifications |
| `build.ps1` | Build script (Windows/MiKTeX) |

All files sit in one flat directory; `main.tex` pulls them in with bare
`\input{}` and no path prefixes, so the folder must stay flat.

## Building

On Windows with [MiKTeX](https://miktex.org):

```powershell
.\build.ps1
```

The script runs `pdflatex` twice (hyperref needs the second pass to settle
its outlines), reports page count, overfull boxes and LaTeX warnings, then
measures how far down the last page the content ends. Auxiliary files go to
`%TEMP%`, so the working directory keeps only sources and the PDF.

Anywhere else, or on Overleaf:

```bash
pdflatex main.tex && pdflatex main.tex
```

Requires `geometry`, `titlesec`, `enumitem`, `microtype`, `hyperref`,
`lmodern`, `xcolor` and `babel` — all standard in TeX Live and MiKTeX.

## Notes on the layout

A few decisions in `config.sty` are load-bearing and easy to undo by
accident.

**Right-aligned dates go through `\entryline`.** It sets `\parfillskip` to
zero inside its own group. Left at the default `0pt plus 1fil`, that glue
competes with `\hfill` when the paragraph ends, and the right-hand text
settles halfway across the line instead of against the margin. Any new
header line should use this macro rather than rolling its own `\hfill`.

**T1 font encoding is deliberate.** Applicant tracking systems read the
PDF's extracted text layer, and under the default OT1 encoding the `fi`
and `fl` ligatures come out as broken glyphs.

**The two-page fit is tuned.** `\baselinestretch` at 1.04, `itemsep` at
1.5pt and the 13mm/10mm margins together land the document just inside two
pages, with roughly one line to spare. Change any of them and re-run the
build to check the page count.

**Skills lines wrap just above 123 characters.** Keeping each under that
stops a line spilling two trailing words onto a line of their own.

## Licence

The LaTeX template, macros and build script are released under the
[MIT Licence](LICENSE) — fork them and put your own CV through them.

That covers the machinery, not the contents. The personal material in
`title.tex`, `education.tex`, `professional_experience.tex`, `projects.tex`,
`skills.tex` and `certification.tex` is one person's employment history and
contact details. Replace it with your own rather than reusing it.
