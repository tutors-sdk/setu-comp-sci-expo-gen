# SETU Computing Expo Brochure Generation System

An automated LaTeX-based system for generating professional brochures showcasing final year computing projects at SETU (South East Technological University) Waterford.

## Overview

This system transforms a single CSV file containing student project data into publication-quality PDF brochures with:
- Student photos and project posters
- Detailed project descriptions
- QR codes linking to project websites
- Multi-format navigation (by programme, subject area, or room)
- Optimized outputs for both print and digital distribution

## Generated Outputs

The system produces two main PDF documents:

1. **Project Showcase** (~141MB) - Full brochures with photos, posters, and detailed descriptions
2. **List of Projects** (~12MB) - Condensed project listing

## Quick Start

### Prerequisites

- Python 3 with pandas and numpy
- LuaLaTeX
- macOS with `sips` (or modify Makefiles to use ImageMagick for cross-platform)
- Make

### Build Complete Brochure

```bash
# Complete build pipeline
make all
```

This runs:
1. `generate-tex` - Generate individual student .tex files from CSV
2. `generate-content` - Extract content-only versions
3. `fix-references` - Update all \input{} paths
4. `build` - Process images and compile PDFs

### Individual Steps

```bash
# Generate student .tex files from CSV
make generate-tex

# Extract content versions
make generate-content

# Fix references to use _content.tex files
make fix-references

# Build images and PDFs
make build

# Clean auxiliary files
make clean

# Clean all generated files
make reset
```

## System Architecture

### 1. Data Input Layer

**Primary Data Source**: `df_student_content.csv` (283 students)

Each row contains:
- Student metadata (Name, SID, Programme)
- Project information (titles, summary, technologies)
- Supervisor details
- Asset references (photo, poster, QR code)
- Room/booth assignment
- Project area classifications

### 2. Code Generation

**Script**: `csv_to_tex_entries.py`

Reads the CSV and LaTeX template to generate individual `.tex` files for each student.

```bash
python3 csv_to_tex_entries.py -v
```

**Template**: `latex/templates/student.tex`

Uses placeholder substitution:
- `[Key]` → Student unique identifier
- `[Name]` → Student name
- `[Summary]` → Project description
- `[Technologies]` → Tech stack
- etc.

### 3. Content Processing Pipeline

The Makefile orchestrates a multi-stage build:

```
CSV → Python Script → Individual .tex files → Content extraction → 
Reference fixing → Image processing → LuaLaTeX → PDFs
```

**Content Extraction**: Strips `\documentclass` and `\begin{document}`...`\end{document}` wrappers to create `*_content.tex` versions that can be included in larger documents.

**Reference Fixing**: Updates all `\input{}` statements to reference `*_content.tex` versions.

### 4. Asset Management

#### Student Photos (`student_images/`, 145MB)
```
orig/ → edited/ → res_print/ (full resolution)
                → res_ebook/ (256px width)
                → res_colm/ (custom size)
```

#### Project Posters (`student_posters/`, 114MB)
- Various orientations (portrait/landscape)
- Dimensions tracked in CSV
- Per-poster scaling factors

#### QR Codes (`student_qr/`, 540KB)
- Links to project landing pages/GitHub repos
- Named by student key

#### Common Images (`common_images/`, 135MB)
- Department branding
- Welcome photos
- Multi-resolution processing

#### Image Processing

Each asset directory has a Makefile that:
1. Copies from `orig/` to `edited/` (for manual editing)
2. Generates `res_print/` (full resolution)
3. Generates `res_ebook/` (compressed for digital distribution)

### 5. LaTeX Document Structure

#### Main Configuration
`latex/setu-computing-graduate-2026.tex`

Features:
- Custom 16:9 aspect ratio (338.7mm × 190.5mm) for presentation-style layout
- TikZ for custom page designs
- Hyperlinked navigation
- PGF keys for student data storage
- FontAwesome icons
- Custom color schemes

#### Main Output Documents

**CExpo_2026_-_Project_Showcase.tex**
```
├─ Welcome messages (Amanda, Lucy, Colm)
├─ Section 1: Undergraduate Programmes (BSc Hons)
│   ├─ Applied Computing
│   ├─ Computer Forensics and Security
│   ├─ Creative Computing
│   ├─ Information Technology Management
│   └─ Software Systems Development
├─ Section 2: HDip Programmes
└─ Section 3: MSc Programmes
```

**CExpo_2026_-_List_of_Projects.tex**
- Condensed format
- Similar structure with less visual content

#### Programme-Level Files

Auto-generated in `output/`:
- `BSc_H_in_Applied_Computing.tex` (main document)
- `BSc_H_in_Applied_Computing_content.tex` (extracted content)
- `BSc_H_in_Applied_Computing_projects.tex` (list of student includes)

Each `*_projects.tex` contains:
```latex
\input{../student_content/Student_Name_ID_content.tex}
\input{../student_content/Another_Student_ID_content.tex}
...
```

## Directory Structure

```
.
├── csv_to_tex_entries.py          # CSV → LaTeX generator
├── df_student_content.csv          # Master data file (283 students)
├── Makefile                        # Main build orchestration
│
├── latex/                          # LaTeX configuration
│   ├── setu-computing-graduate-2026.tex
│   └── templates/
│       └── student.tex             # Student entry template
│
├── common_content/                 # Welcome messages
│   ├── Welcome_Amanda.tex
│   ├── Welcome_Lucy.tex
│   └── Welcome_Colm.tex
│
├── common_images/                  # Department branding (135MB)
│   ├── orig/
│   ├── edited/
│   ├── res_print/
│   └── res_ebook/
│
├── student_content/                # Generated student .tex files (272 files)
│   ├── Student_Name_ID.tex
│   └── Student_Name_ID_content.tex
│
├── student_images/                 # Student photos (145MB)
│   ├── orig/
│   ├── edited/
│   ├── res_print/
│   ├── res_ebook/
│   └── res_colm/
│
├── student_posters/                # Project posters (114MB)
│   ├── orig/
│   ├── edited/
│   ├── res_print/
│   └── res_ebook/
│
├── student_qr/                     # QR codes (540KB)
│   └── Student_Name_ID.png
│
└── output/                         # Final PDFs and programme files (158MB)
    ├── CExpo_2026_-_Project_Showcase.pdf
    ├── CExpo_2026_-_List_of_Projects.pdf
    ├── BSc_H_in_*.tex
    ├── HDip_in_*.tex
    └── MSc_in_*.tex
```

## CSV Data Model

### Required Columns

| Column | Description | Example |
|--------|-------------|---------|
| `Key` | Unique identifier | `Davin_Barron_53773` |
| `SortName` | Surname, Firstname | `Barron, Davin` |
| `SID` | Student ID | `W20102008` |
| `Name` | Full name | `Davin Barron` |
| `Programme` | Full programme title | `Bachelor of Science (Honours) in Applied Computing` |

### Project Information

| Column | Description |
|--------|-------------|
| `CommercialTitle` | Project name (LaTeX-safe) |
| `AcademicTitle` | Academic project title |
| `Summary` | Project description (LaTeX-safe) |
| `Technologies` | Comma-separated tech stack |
| `ProjectURL` | Landing page or GitHub URL |

### Supervision

| Column | Description |
|--------|-------------|
| `SupervisorLabel` | "Project Supervisor" or "Project Supervisors" |
| `Supervisor` | Supervisor name(s) |

### Classification

| Column | Description |
|--------|-------------|
| `ProjectAreas` | Comma-separated areas: `AI ML Development,Game Development,...` |
| `ProjectAreasTeX` | Formatted for LaTeX with `\pgfkeysvalueof` |

### Assets

| Column | Type | Description |
|--------|------|-------------|
| `Photo` | String | Filename (without extension) |
| `HasPhoto` | Boolean | `True`/`False` |
| `Poster` | String | Filename (without extension) |
| `HasPoster` | Boolean | `True`/`False` |
| `PosterWidth` | Integer | Pixels |
| `PosterHeight` | Integer | Pixels |
| `PosterOrientation` | String | `portrait`/`landscape` |
| `PosterScale` | Float | Scaling factor |
| `QR` | String | QR code filename |
| `HasQR` | Boolean | `True`/`False` |

### Physical Expo

| Column | Description |
|--------|-------------|
| `Room` | Room assignment (e.g., `TL2.49`) |
| `Number` | Booth number |

## Project Areas

The system supports multiple project classifications:

- **AI ML Development** - Machine learning, chatbots, predictive systems
- **Game Development** - Unity games, 2D/3D, roguelites
- **Cloud Computing** - AWS, Docker, Kubernetes
- **Computer Security** - Forensics, scam detection, network security
- **Software Development** - Back End, Front End, Mobile, Core, Web
- **Database and Analytics** - Data systems and analysis
- **Media Development and Production** - Multimedia projects
- **Information Systems and Modelling** - Business systems
- **Computer Networks** - Network architecture and management
- **Work Based Project** - Industry partnerships
- **Open Source** - Open source contributions
- **Personal Independent Project** - Self-directed research

## Technologies Used

### Build System
- Python 3 (pandas, numpy)
- GNU Make
- Bash/sed for text processing
- `sips` (macOS) for image resizing

### LaTeX Ecosystem
- LuaLaTeX
- TikZ for graphics
- PGF keys for data storage
- FontAwesome for icons
- Hyperref for navigation
- Geometry for custom page sizes

### Version Control
- Git

## LuaLaTeX Compilation

PDFs are compiled with two passes for proper TOC/reference resolution:

```bash
lualatex CExpo_2026_-_Project_Showcase.tex
lualatex CExpo_2026_-_Project_Showcase.tex
```

Generates auxiliary files:
- `.aux` - Cross-references
- `.log` - Compilation log
- `.out` - Hyperlinks
- `.areas` - Project areas index
- `.rooms` - Room index
- `.programmes` - Programme index
- `.projects` - Project listings

## Use Cases

### 1. Physical Expo
- Room/number assignments for student booths
- Printed brochures for visitors
- Navigation by room location

### 2. Digital Distribution
- Ebook version for online sharing
- Hyperlinked navigation by programme or subject area
- QR codes link to project websites

### 3. Individual Student Portfolios
- Each student can compile their standalone `.tex` file
- Personal project showcase document

### 4. Programme-Specific Materials
- Extract just one programme's projects
- Department-level reporting

## Customization

### Adding a New Student

1. Add row to `df_student_content.csv`
2. Add student photo to `student_images/orig/`
3. Add project poster to `student_posters/orig/`
4. Generate QR code in `student_qr/`
5. Run `make all`

### Modifying Welcome Messages

Edit files in `common_content/`:
- `Welcome_Amanda.tex`
- `Welcome_Lucy.tex`
- `Welcome_Colm.tex`

### Changing Layout/Styling

Main configuration: `latex/setu-computing-graduate-2026.tex`

- Page dimensions: Lines 73-79
- Colors: Search for color definitions
- Navigation icons: Lines 54-67
- Fonts: Throughout configuration file

### Template Customization

Student entry template: `latex/templates/student.tex`

Uses placeholders like `[Key]`, `[Name]`, etc. that are replaced by Python script.

## LaTeX Special Characters

The system handles special characters in two columns:
- `SummaryRaw` → `Summary` (LaTeX-escaped)
- `CommercialTitleRaw` → `CommercialTitle` (LaTeX-escaped)

Common conversions:
- `&` → `\&`
- `%` → `\%`
- `_` → `\_`
- `#` → `\#`
- `**text**` → `{\bfseries text}` (bold)
- Apostrophes → `\textquoteleft{}` or `\textquoteright{}`

## Troubleshooting

### Image Not Found
- Ensure file exists in appropriate `orig/` directory
- Run `make build` in image directory to regenerate
- Check CSV has correct filename (without extension)

### LaTeX Compilation Error
- Check `.log` file in `output/`
- Ensure all `*_content.tex` files generated
- Run `make fix-references` to update paths

### Missing Student Entry
- Verify CSV row is valid
- Re-run `python3 csv_to_tex_entries.py -v`
- Check `student_content/` for generated file

### sips Command Not Found (Non-macOS)
Replace `sips` with ImageMagick in Makefiles:
```makefile
# Replace this:
sips --resampleWidth 256 $< --out $@

# With this:
convert $< -resize 256x $@
```

## Performance Notes

- **Full build time**: ~5-10 minutes depending on hardware
- **Image processing**: Most time-consuming step
- **LuaLaTeX compilation**: ~2-3 minutes per main document
- **CSV processing**: <1 second

## Future Improvements

1. **Documentation**: Add inline code comments
2. **Validation**: CSV schema validation before processing
3. **Asset Checking**: Verify all referenced images exist
4. **Cross-platform**: Replace macOS-specific tools
5. **Error Handling**: Better error messages in Python script
6. **Incremental Builds**: Only regenerate changed files
7. **Web Preview**: Generate HTML preview alongside PDFs

## Contributing

This system is maintained by the Department of Computing and Mathematics at SETU Waterford.

For questions or issues:
- Contact: FYP Coordinator (Lucy White)
- Department: Computing and Mathematics
- Institution: SETU Waterford

## License

Internal use for SETU Computing Department.

## Acknowledgments

- **FYP Coordinator**: Lucy White
- **Department Head**: Amanda Gibney
- **Project Supervisors**: All faculty members supervising final year projects
- **Students**: 283 final year students (2026 cohort)

---

**Last Updated**: May 2026  
**System Version**: 2026 Computing Expo  
**Generated PDFs**: CExpo_2026_-_Project_Showcase.pdf, CExpo_2026_-_List_of_Projects.pdf
