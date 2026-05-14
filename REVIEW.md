# Architectural Review: SETU Computing Expo Brochure Generation System

**Review Date**: May 2026  
**Reviewer**: Technical Architecture Assessment  
**System Version**: 2026 Computing Expo  
**Codebase Size**: ~600 lines (Python + Makefiles + LaTeX config)

---

## Executive Summary

This system successfully generates professional-quality brochures from structured data, demonstrating solid engineering principles with clear separation of data, templates, and build orchestration. The architecture is fundamentally sound for its annual use case but shows technical debt typical of organically-grown academic tooling.

**Overall Assessment**: ⭐⭐⭐⭐☆ (4/5)

**Key Strengths**:
- Single source of truth (CSV-driven)
- Automated build pipeline
- Modular, reusable student entries
- Multi-format output optimization

**Key Weaknesses**:
- Platform dependency (macOS)
- Minimal error handling and validation
- Complex text processing in shell scripts
- Lack of automated testing
- Steep learning curve for maintainers

**Recommendation**: Implement **Level 1 (Quick Wins)** and **Level 2 (Modest Improvements)** over the next 1-2 development cycles. Consider **Level 3 (Significant Refactoring)** only if the system expands to other departments or institutions.

---

## 1. Overall Structure Analysis

### 1.1 Architecture Pattern

**Current**: **Data-Driven Pipeline Architecture**

```
CSV Data → Python Generator → LaTeX Files → Make Processing → PDFs
```

**Assessment**: ✅ Appropriate for this domain

The linear pipeline is well-suited for batch document generation. The architecture follows Unix philosophy: small tools doing one thing well, composed via Make.

### 1.2 Separation of Concerns

| Concern | Implementation | Grade |
|---------|---------------|-------|
| **Data Layer** | CSV file | ⭐⭐⭐⭐⭐ Excellent |
| **Template Layer** | `latex/templates/student.tex` | ⭐⭐⭐⭐☆ Good |
| **Generation Logic** | Python script | ⭐⭐⭐☆☆ Fair |
| **Build Orchestration** | Makefiles | ⭐⭐⭐☆☆ Fair |
| **Asset Management** | Directory structure + Make | ⭐⭐⭐⭐☆ Good |
| **Presentation** | LaTeX configuration | ⭐⭐⭐⭐☆ Good |

**Strengths**:
- Clear data/code separation
- Templates independent of generation logic
- Asset processing isolated to subdirectories

**Weaknesses**:
- Content extraction logic embedded in Makefile (should be in Python)
- LaTeX escaping happens manually in CSV (should be automated)
- No clear abstraction for "Student" or "Project" entities

### 1.3 Directory Organization

**Assessment**: ✅ Logical and discoverable

```
data (CSV) + templates → generator → content → assets → output
```

The structure is intuitive. Related files are co-located. The separation of `orig/`, `edited/`, `res_print/`, `res_ebook/` is exemplary asset management.

**Minor Issue**: `output/` contains both generated intermediate files (programme `.tex` files) and final PDFs. Consider splitting:
```
output/
├── intermediate/  # Generated .tex files
└── pdf/           # Final deliverables
```

---

## 2. Comprehensibility Assessment

### 2.1 Code Readability

#### Python Script (`csv_to_tex_entries.py`)

**Grade**: ⭐⭐⭐⭐☆ Good

**Strengths**:
- Simple, linear logic
- Clear function names (`to_tex`, `run`)
- Template-based approach is easy to understand

**Weaknesses**:
```python
fields = set(re.findall(r"\[\w+\]" , template)) - set(["[twoside]", "[SID]"])
```
- Magic exclusions (`[twoside]`, `[SID]`) not documented
- No type hints beyond argument annotation
- No docstrings
- Regex pattern not explained

**Improvement**:
```python
def extract_template_placeholders(template: str) -> set[str]:
    """
    Extract placeholders like [Name], [Summary] from template.
    
    Excludes LaTeX-specific tokens like [twoside] and [SID] which
    are used as LaTeX options, not data placeholders.
    """
    LATEX_TOKENS = {"[twoside]", "[SID]"}  # Not data fields
    all_matches = set(re.findall(r"\[\w+\]", template))
    return all_matches - LATEX_TOKENS
```

#### Makefiles

**Grade**: ⭐⭐☆☆☆ Poor to Fair

**Strengths**:
- Dependency management is correct
- Phony targets well-defined
- Comments indicate purpose

**Weaknesses**:
- **Complex shell logic** in `generate-content` target:
  ```makefile
  sed -n '/^\\begin{document}/,/^\\end{document}/p' "$$file" | sed '1d;$$d'
  ```
  This sed wizardry extracts document body but requires shell expertise to understand.

- **Fragile text processing** in `fix-references`:
  ```makefile
  sed -i.auto_bak \
    -e 's/\\input{\.\.\/common_content\/Welcome_\([^}]*\)\.tex}/\\input{..\/common_content\/Welcome_\1_content.tex}/g'
  ```
  Escaping backslashes and regex pattern matching is error-prone and hard to maintain.

- **No error checking**: If a student file fails to generate, Make continues silently.

**Recommendation**: Move text processing to Python where regex is more readable and testable.

#### LaTeX Configuration

**Grade**: ⭐⭐⭐☆☆ Fair

**Strengths**:
- Modular includes
- PGF keys provide structured data access
- Custom commands for consistency

**Weaknesses**:
- 1000+ lines in `setu-computing-graduate-2026.tex` (not reviewed in full, but likely complex)
- Magic numbers for positioning (e.g., `$(P.north west) + (11cm,-6.7cm)$`)
- No comments explaining custom macros

### 2.2 Learning Curve

**For New Maintainers**: ⚠️ **Steep**

Required knowledge:
1. Python (pandas, regex)
2. LaTeX (advanced: TikZ, PGF keys, custom document classes)
3. Make (including shell integration)
4. CSV data modeling
5. Image processing concepts

**Estimated onboarding time**: 
- Basic changes (update welcome text): 1 hour
- Add new student: 2 hours (with guidance)
- Fix generation bug: 4-8 hours
- Modify layout: 8-16 hours (requires LaTeX expertise)

**Mitigation**: README.md helps significantly. Consider adding:
- Commented example student entry
- Video walkthrough of build process
- Troubleshooting decision tree

### 2.3 Documentation

**Grade**: ⭐⭐⭐☆☆ Fair (now ⭐⭐⭐⭐☆ with README.md)

**Before this review**:
- No README at root
- No inline comments in Python
- Minimal comments in Makefiles
- No architecture diagram

**Current state**:
- Comprehensive README.md ✅
- Still lacks inline documentation
- No API/function documentation
- No examples or tutorials

---

## 3. Maintainability Assessment

### 3.1 Change Impact Analysis

**Scenario 1: Add new student**

Impact: ✅ **Low** (as designed)
1. Add CSV row
2. Add assets (photo, poster, QR)
3. Run `make all`

**Scenario 2: Change project area classification**

Impact: ⚠️ **Medium**
- Update CSV column `ProjectAreasTeX`
- Potentially update LaTeX area definitions
- No clear documentation of valid values
- Could break LaTeX compilation if area doesn't exist

**Scenario 3: Add new programme**

Impact: ⚠️ **Medium-High**
- Update CSV with new programme name
- Likely need to modify `output/CExpo_2026_-_Project_Showcase.tex` to include new section
- May need to create new programme template
- No automated generation of programme-level files (appears manual?)

**Scenario 4: Change page layout**

Impact: ❌ **High**
- Requires deep LaTeX/TikZ knowledge
- Magic numbers scattered throughout
- No layout configuration file
- Testing requires full rebuild (~5-10 min)

**Scenario 5: Port to Windows/Linux**

Impact: ❌ **Very High**
- `sips` is macOS-only (need ImageMagick)
- `sed -i.auto_bak` syntax differs on Linux
- Path separators might differ
- Untested on other platforms

### 3.2 Error Handling

**Grade**: ⭐☆☆☆☆ Poor

#### Missing Validations

1. **CSV Schema**: No validation that required columns exist
   ```python
   # Current: Silent failure if column missing
   to_tex(row[column]) if column in df.columns else ""
   
   # Better: Fail fast with clear error
   if not all(col in df.columns for col in REQUIRED_COLUMNS):
       raise ValueError(f"Missing columns: {REQUIRED_COLUMNS - set(df.columns)}")
   ```

2. **Asset Existence**: No check if `student_images/orig/Davin_Barron_53773.*` exists
   - LaTeX compilation fails late in process
   - Error message cryptic: `! Package pdftex.def Error: File 'student_images/res_ebook/Davin_Barron_53773.png' not found`

3. **LaTeX Special Characters**: Relies on manual CSV preparation
   - Should auto-escape `&`, `%`, `_`, `#`, etc.
   - Current approach error-prone (easy to forget)

4. **Duplicate Keys**: No check for duplicate student keys in CSV
   - Last entry would silently overwrite first

5. **Invalid Data**: No validation of:
   - URL format for `ProjectURL`
   - Boolean values for `HasPhoto`, `HasPoster`
   - Integer values for dimensions
   - Valid programme names

#### Build Failures

**Current behavior**: Make continues even if student file generation fails

```makefile
# Current: No error checking
for file in *.tex; do
    sed -n '/^\\begin{document}/,/^\\end{document}/p' "$$file" | sed '1d;$$d' > "$${file%.tex}_content.tex"
done
```

**Better**:
```makefile
for file in *.tex; do
    sed -n '/^\\begin{document}/,/^\\end{document}/p' "$$file" | sed '1d;$$d' > "$${file%.tex}_content.tex" || exit 1
done
```

### 3.3 Testing

**Grade**: ⭐☆☆☆☆ Poor (No tests)

**Missing tests**:
- Unit tests for `csv_to_tex_entries.py`
- Integration test with sample data
- Validation that all CSV students have corresponding assets
- PDF generation smoke test
- Cross-platform compatibility tests

**Impact**: 
- Regressions discovered only at PDF generation (late feedback)
- Difficult to refactor with confidence
- Manual QA required each year

### 3.4 Technical Debt

| Debt Item | Severity | Effort to Fix |
|-----------|----------|---------------|
| No input validation | High | Medium (1-2 days) |
| Platform dependency (sips) | Medium | Low (4 hours) |
| Hardcoded values in LaTeX | Medium | High (1 week) |
| Complex sed in Makefiles | Medium | Medium (1 day) |
| No tests | High | High (1 week) |
| Manual LaTeX escaping | Medium | Low (4 hours) |
| No error logging | Low | Low (2 hours) |
| Mixed standalone/content files | Low | N/A (design choice) |

**Total estimated effort to clear**: 2-3 weeks of focused development

---

## 4. Scalability Assessment

### 4.1 Current Capacity

**Students**: 283 ✅ Handles well

**Build time**: ~5-10 minutes ✅ Acceptable for annual use

**PDF size**: 141MB ⚠️ Large but manageable

### 4.2 Scaling Scenarios

**500 students**: ✅ Should work (linear scaling)

**Multiple departments**: ⚠️ Would need refactoring
- Hardcoded paths in LaTeX
- Single CSV becomes unwieldy
- Suggest: Department-specific CSVs with merge step

**Weekly updates**: ⚠️ Build time becomes problematic
- Need incremental builds
- Consider caching/memoization

**Multi-institution**: ❌ Significant refactoring required
- Institution-specific branding hardcoded
- Would need configuration-driven approach

---

## 5. Improvement Strategy

### Level 1: Quick Wins (1-3 days effort)

These changes provide immediate value with minimal risk.

#### 1.1 Input Validation (Priority: HIGH)

**File**: `csv_to_tex_entries.py`

```python
import sys

REQUIRED_COLUMNS = {
    'Key', 'Name', 'Programme', 'Summary', 'Technologies',
    'ProjectURL', 'Supervisor', 'Room', 'Number'
}

OPTIONAL_COLUMNS = {
    'Photo', 'HasPhoto', 'Poster', 'HasPoster', 'QR', 'HasQR'
}

def validate_csv(df: pd.DataFrame):
    """Validate CSV has required columns and data quality."""
    missing = REQUIRED_COLUMNS - set(df.columns)
    if missing:
        print(f"ERROR: Missing required columns: {missing}", file=sys.stderr)
        sys.exit(1)
    
    # Check for duplicate keys
    duplicates = df[df.duplicated(subset=['Key'], keep=False)]
    if not duplicates.empty:
        print(f"ERROR: Duplicate keys found:", file=sys.stderr)
        print(duplicates[['Key', 'Name']], file=sys.stderr)
        sys.exit(1)
    
    # Check for empty required fields
    for col in ['Key', 'Name']:
        empty = df[df[col].isna() | (df[col] == '')]
        if not empty.empty:
            print(f"ERROR: Empty {col} in rows:", file=sys.stderr)
            print(empty[['Key', 'Name']], file=sys.stderr)
            sys.exit(1)
    
    print(f"✓ CSV validation passed: {len(df)} students")

def run(args):
    df = pd.read_csv("df_student_content.csv")
    validate_csv(df)  # Add this line
    # ... rest of existing code
```

**Impact**: Catches errors before LaTeX compilation, saving 5-10 minutes per error.

#### 1.2 Asset Existence Check (Priority: HIGH)

```python
import os
from pathlib import Path

def check_assets(df: pd.DataFrame):
    """Verify all referenced assets exist."""
    errors = []
    
    for _, row in df.iterrows():
        key = row['Key']
        
        # Check photo
        if row.get('HasPhoto') == 'True':
            photo_path = Path(f"student_images/orig/{row['Photo']}")
            if not any(photo_path.with_suffix(ext).exists() 
                      for ext in ['.png', '.jpg', '.jpeg', '.pdf']):
                errors.append(f"Missing photo for {key}: {row['Photo']}")
        
        # Check poster
        if row.get('HasPoster') == 'True':
            poster_path = Path(f"student_posters/orig/{row['Poster']}")
            if not any(poster_path.with_suffix(ext).exists()
                      for ext in ['.png', '.jpg', '.jpeg', '.pdf']):
                errors.append(f"Missing poster for {key}: {row['Poster']}")
        
        # Check QR
        if row.get('HasQR') == 'True':
            qr_path = Path(f"student_qr/{row['QR']}.png")
            if not qr_path.exists():
                errors.append(f"Missing QR code for {key}: {row['QR']}")
    
    if errors:
        print("ERROR: Missing assets:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        sys.exit(1)
    
    print(f"✓ Asset check passed")
```

**Impact**: Immediate feedback on missing assets, prevents late-stage build failures.

#### 1.3 Automatic LaTeX Escaping (Priority: MEDIUM)

```python
def latex_escape(text: str) -> str:
    """Escape special LaTeX characters."""
    if pd.isna(text):
        return ""
    
    text = str(text)
    replacements = {
        '&': r'\&',
        '%': r'\%',
        '$': r'\$',
        '#': r'\#',
        '_': r'\_',
        '{': r'\{',
        '}': r'\}',
        '~': r'\textasciitilde{}',
        '^': r'\^{}',
        '\\': r'\textbackslash{}',
    }
    
    for char, escaped in replacements.items():
        text = text.replace(char, escaped)
    
    return text

def to_tex(value, escape=True):
    """Convert value to TeX string, optionally escaping special chars."""
    if pd.isna(value):
        return ""
    if type(value) == float:
        return str(int(value)) if int(value) == value else str(value)
    return latex_escape(str(value)) if escape else str(value)
```

**Impact**: Eliminates manual CSV preparation step, reduces errors.

#### 1.4 Cross-Platform Image Processing (Priority: MEDIUM)

**File**: `*/Makefile`

```makefile
# Detect platform and use appropriate tool
UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
    # macOS: use sips
    RESIZE_CMD = sips --resampleWidth 256 $$< --out $$@
else
    # Linux/Windows: use ImageMagick
    RESIZE_CMD = convert $$< -resize 256x $$@
endif

res_ebook/%.png: edited/%.png
	$(RESIZE_CMD)
```

**Impact**: System works on Linux and Windows (with ImageMagick installed).

#### 1.5 Better Error Messages in Makefiles (Priority: LOW)

```makefile
generate-content:
	@echo "Extracting content versions..."
	@cd student_content && \
	for file in *.tex; do \
		if [ "$$file" != "*_content.tex" ] && ! echo "$$file" | grep -q "_content.tex$$" && grep -q "^\\\\documentclass" "$$file" 2>/dev/null; then \
			sed -n '/^\\begin{document}/,/^\\end{document}/p' "$$file" | sed '1d;$$d' > "$${file%.tex}_content.tex" || { echo "ERROR processing $$file"; exit 1; }; \
		fi; \
	done
	@echo "✓ Content extraction complete."
```

**Impact**: Build failures are clearer and stop immediately.

---

### Level 2: Modest Improvements (1-2 weeks effort)

These changes improve maintainability and reduce technical debt.

#### 2.1 Consolidate Text Processing in Python (Priority: HIGH)

**Problem**: Content extraction and reference fixing are in Makefile using sed.

**Solution**: Move to Python script.

**New file**: `build_utils.py`

```python
#!/usr/bin/env python3
"""Utility functions for brochure build process."""

import re
from pathlib import Path
from typing import List

def extract_content(tex_file: Path) -> str:
    """
    Extract content between \\begin{document} and \\end{document}.
    
    Args:
        tex_file: Path to standalone .tex file
        
    Returns:
        Content without document wrapper
    """
    content = tex_file.read_text()
    
    # Match everything between \begin{document} and \end{document}
    match = re.search(
        r'\\begin\{document\}(.*?)\\end\{document\}',
        content,
        re.DOTALL
    )
    
    if not match:
        raise ValueError(f"No document environment found in {tex_file}")
    
    return match.group(1).strip()

def generate_content_files(source_dir: Path):
    """
    Generate _content.tex versions for all standalone .tex files.
    
    Args:
        source_dir: Directory containing .tex files
    """
    processed = 0
    
    for tex_file in source_dir.glob("*.tex"):
        # Skip content files and files without documentclass
        if tex_file.stem.endswith("_content"):
            continue
        
        content = tex_file.read_text()
        if "\\documentclass" not in content:
            continue
        
        try:
            extracted = extract_content(tex_file)
            content_file = tex_file.with_name(f"{tex_file.stem}_content.tex")
            content_file.write_text(extracted + "\n")
            processed += 1
        except ValueError as e:
            print(f"Warning: {e}")
    
    print(f"✓ Generated {processed} content files in {source_dir}")

def fix_references(tex_file: Path):
    """
    Update \\input{} statements to use _content.tex versions.
    
    Args:
        tex_file: Main document to fix
    """
    content = tex_file.read_text()
    
    # Fix common_content references
    content = re.sub(
        r'\\input\{(\.\./common_content/Welcome_[^}]*?)\.tex\}',
        r'\\input{\1_content.tex}',
        content
    )
    
    # Fix programme references
    content = re.sub(
        r'\\input\{((?:BSc|HDip|MSc)_[^}]*?)\.tex\}',
        r'\\input{\1_content.tex}',
        content
    )
    
    # Fix student references
    content = re.sub(
        r'\\input\{(\.\./student_content/[^}]*?)\.tex\}',
        r'\\input{\1_content.tex}',
        content
    )
    
    tex_file.write_text(content)
    print(f"✓ Fixed references in {tex_file.name}")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: build_utils.py [generate-content|fix-references]")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "generate-content":
        generate_content_files(Path("student_content"))
        generate_content_files(Path("common_content"))
        generate_content_files(Path("output"))
    
    elif command == "fix-references":
        fix_references(Path("output/CExpo_2026_-_Project_Showcase.tex"))
        fix_references(Path("output/CExpo_2026_-_List_of_Projects.tex"))
        for f in Path("output").glob("*_projects.tex"):
            fix_references(f)
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
```

**Updated Makefile**:
```makefile
generate-content:
	@echo "Extracting content versions..."
	python3 build_utils.py generate-content

fix-references:
	@echo "Updating references to use _content.tex files..."
	python3 build_utils.py fix-references
```

**Benefits**:
- More readable (Python vs sed regex)
- Testable (can write unit tests)
- Better error messages
- Easier to extend

#### 2.2 Configuration File (Priority: MEDIUM)

**Problem**: Hardcoded values scattered across files.

**New file**: `config.yaml`

```yaml
# Brochure Configuration

year: 2026
event_name: "Computing Expo"

# Paths
paths:
  csv_data: "df_student_content.csv"
  templates: "latex/templates"
  student_content: "student_content"
  output: "output"
  
  assets:
    student_images: "student_images"
    student_posters: "student_posters"
    student_qr: "student_qr"
    common_images: "common_images"

# Image processing
images:
  ebook_width: 256  # pixels
  formats:
    - png
    - jpg
    - jpeg
    - pdf

# Document settings
documents:
  - name: "CExpo_2026_-_Project_Showcase"
    title: "2026 Computing Expo - Project Showcase"
    type: "showcase"
    
  - name: "CExpo_2026_-_List_of_Projects"
    title: "2026 Computing Expo - List of Projects"
    type: "summary"

# LaTeX
latex:
  engine: "lualatex"
  passes: 2
  
# Validation
validation:
  required_columns:
    - Key
    - Name
    - Programme
    - Summary
    - Technologies
    - Supervisor
    - Room
    - Number
  
  valid_programmes:
    - "Bachelor of Science (Honours) in Applied Computing"
    - "Bachelor of Science (Honours) in Computer Forensics and Security"
    - "Bachelor of Science (Honours) in Creative Computing"
    - "Bachelor of Science (Honours) in Information Technology Management"
    - "Bachelor of Science (Honours) in Software Systems Development"
    - "Higher Diploma in Science in Computing (Software Development)"
    - "Higher Diploma in Science in Computing (Data Analytics)"
    - "MSc in Computing (Software Architecture)"
    - "MSc in Computing (Information Systems Processes)"
```

**Update Python** to load config:

```python
import yaml

def load_config():
    """Load configuration from config.yaml."""
    with open("config.yaml") as f:
        return yaml.safe_load(f)

config = load_config()
csv_path = config['paths']['csv_data']
```

**Benefits**:
- Single place to update paths/settings
- Easy to create config for different years
- Validation rules are explicit
- Can generate test configs

#### 2.3 Add Basic Testing (Priority: MEDIUM)

**New file**: `test_generator.py`

```python
#!/usr/bin/env python3
"""Tests for CSV to TeX generator."""

import unittest
import tempfile
import pandas as pd
from pathlib import Path
from csv_to_tex_entries import to_tex, validate_csv, latex_escape

class TestLatexEscape(unittest.TestCase):
    def test_ampersand(self):
        self.assertEqual(latex_escape("R&D"), r"R\&D")
    
    def test_percent(self):
        self.assertEqual(latex_escape("100%"), r"100\%")
    
    def test_underscore(self):
        self.assertEqual(latex_escape("file_name"), r"file\_name")
    
    def test_combined(self):
        self.assertEqual(
            latex_escape("C# & Python"),
            r"C\# \& Python"
        )

class TestValidation(unittest.TestCase):
    def test_missing_columns(self):
        df = pd.DataFrame({'Key': ['test']})
        with self.assertRaises(SystemExit):
            validate_csv(df)
    
    def test_duplicate_keys(self):
        df = pd.DataFrame({
            'Key': ['student1', 'student1'],
            'Name': ['Alice', 'Bob'],
            'Programme': ['BSc', 'BSc'],
            'Summary': ['...', '...'],
            'Technologies': ['...', '...'],
            'Supervisor': ['...', '...'],
            'Room': ['A', 'B'],
            'Number': [1, 2]
        })
        with self.assertRaises(SystemExit):
            validate_csv(df)

class TestContentExtraction(unittest.TestCase):
    def test_extract_content(self):
        from build_utils import extract_content
        
        tex_content = """
\\documentclass{article}
\\begin{document}
Hello World
\\end{document}
"""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.tex', delete=False) as f:
            f.write(tex_content)
            temp_path = Path(f.name)
        
        try:
            extracted = extract_content(temp_path)
            self.assertEqual(extracted.strip(), "Hello World")
        finally:
            temp_path.unlink()

if __name__ == '__main__':
    unittest.main()
```

**Run tests**:
```bash
python3 -m pytest test_generator.py
# or
python3 test_generator.py
```

**Benefits**:
- Catch regressions early
- Document expected behavior
- Enable confident refactoring

#### 2.4 Generate Sample Data (Priority: LOW)

**New file**: `generate_sample_data.py`

```python
#!/usr/bin/env python3
"""Generate sample CSV for testing."""

import pandas as pd

sample_data = [
    {
        'Key': 'John_Doe_12345',
        'SortName': 'Doe, John',
        'SID': 'W20100001',
        'Name': 'John Doe',
        'Programme': 'Bachelor of Science (Honours) in Applied Computing',
        'Photo': 'John_Doe_12345',
        'Poster': 'John_Doe_12345',
        'CommercialTitle': 'Sample Project',
        'AcademicTitle': 'An Academic Title for Sample Project',
        'Summary': 'This is a sample project summary with special characters: & % # _',
        'Technologies': 'Python, Django, PostgreSQL',
        'ProjectURL': 'https://example.com/project',
        'SupervisorLabel': 'Project Supervisor',
        'Supervisor': 'Dr. Jane Smith',
        'ProjectAreasTeX': r'\pgfkeysvalueof{/area/AI ML Development/Name}',
        'ProjectAreas': 'AI ML Development',
        'HasPhoto': True,
        'HasPoster': True,
        'PosterWidth': 1587,
        'PosterHeight': 2245,
        'PosterOrientation': 'portrait',
        'PosterScale': 1,
        'QR': 'SD',
        'HasQR': True,
        'Room': 'TL2.49',
        'Number': 1
    },
    # Add 2-3 more sample students
]

df = pd.DataFrame(sample_data)
df.to_csv('sample_data.csv', index=False)
print("✓ Generated sample_data.csv with {} students".format(len(df)))
```

**Benefits**:
- Test build without full dataset
- Onboarding for new maintainers
- Faster iteration during development

#### 2.5 Logging and Progress Reporting (Priority: LOW)

```python
import logging
from tqdm import tqdm

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def run(args):
    logger.info("Loading CSV data...")
    df = pd.read_csv("df_student_content.csv")
    
    logger.info(f"Validating {len(df)} student records...")
    validate_csv(df)
    check_assets(df)
    
    logger.info("Loading template...")
    template = open("latex/templates/student.tex", "r").read()
    
    logger.info("Generating TeX files...")
    for _, row in tqdm(df.sort_values("SortName").iterrows(), 
                       total=len(df),
                       desc="Processing students"):
        # ... generation logic
    
    logger.info("✓ Generation complete")
```

**Benefits**:
- Better visibility into long-running builds
- Easier debugging
- Professional user experience

---

### Level 3: Significant Refactoring (3-6 weeks effort)

These changes require substantial development but future-proof the system.

#### 3.1 Object-Oriented Redesign (Priority: MEDIUM)

**Problem**: Data is manipulated as dictionaries; no clear domain model.

**Solution**: Introduce domain objects.

**New file**: `models.py`

```python
#!/usr/bin/env python3
"""Domain models for brochure generation."""

from dataclasses import dataclass, field
from typing import List, Optional
from pathlib import Path
import re

@dataclass
class Asset:
    """Represents a student asset (photo, poster, QR code)."""
    name: str
    has_asset: bool
    asset_type: str  # 'photo', 'poster', 'qr'
    
    def path(self, base_dir: str, resolution: str = 'ebook') -> Path:
        """Get path to asset at specified resolution."""
        if not self.has_asset:
            return None
        
        if self.asset_type == 'qr':
            return Path(f"{base_dir}/{self.name}.png")
        
        return Path(f"{base_dir}/res_{resolution}/{self.name}")
    
    def exists(self, base_dir: str) -> bool:
        """Check if asset file exists."""
        if not self.has_asset:
            return True
        
        if self.asset_type == 'qr':
            return self.path(base_dir).exists()
        
        # Check for any supported format
        base = Path(f"{base_dir}/orig/{self.name}")
        return any(base.with_suffix(ext).exists() 
                  for ext in ['.png', '.jpg', '.jpeg', '.pdf'])

@dataclass
class Poster(Asset):
    """Represents a project poster with dimensions."""
    width: Optional[int] = None
    height: Optional[int] = None
    orientation: str = 'portrait'
    scale: float = 1.0
    
    def __post_init__(self):
        self.asset_type = 'poster'

@dataclass
class Student:
    """Represents a student and their project."""
    key: str
    sid: str
    name: str
    sort_name: str
    programme: str
    
    # Project info
    commercial_title: str
    academic_title: str
    summary: str
    technologies: List[str]
    project_url: str
    project_areas: List[str]
    
    # Supervision
    supervisor_label: str
    supervisor: str
    
    # Physical location
    room: str
    number: int
    
    # Assets
    photo: Asset = field(default_factory=lambda: Asset('', False, 'photo'))
    poster: Poster = field(default_factory=lambda: Poster('', False))
    qr: Asset = field(default_factory=lambda: Asset('', False, 'qr'))
    
    @classmethod
    def from_csv_row(cls, row: dict) -> 'Student':
        """Create Student from CSV row."""
        return cls(
            key=row['Key'],
            sid=row.get('SID', ''),
            name=row['Name'],
            sort_name=row['SortName'],
            programme=row['Programme'],
            
            commercial_title=row['CommercialTitle'],
            academic_title=row['AcademicTitle'],
            summary=row['Summary'],
            technologies=cls._parse_list(row['Technologies']),
            project_url=row['ProjectURL'],
            project_areas=cls._parse_list(row['ProjectAreas']),
            
            supervisor_label=row['SupervisorLabel'],
            supervisor=row['Supervisor'],
            
            room=row['Room'],
            number=int(row['Number']),
            
            photo=Asset(
                row.get('Photo', ''),
                row.get('HasPhoto') == 'True',
                'photo'
            ),
            poster=Poster(
                row.get('Poster', ''),
                row.get('HasPoster') == 'True',
                width=int(row['PosterWidth']) if row.get('PosterWidth') else None,
                height=int(row['PosterHeight']) if row.get('PosterHeight') else None,
                orientation=row.get('PosterOrientation', 'portrait'),
                scale=float(row.get('PosterScale', 1.0))
            ),
            qr=Asset(
                row.get('QR', ''),
                row.get('HasQR') == 'True',
                'qr'
            )
        )
    
    @staticmethod
    def _parse_list(value: str) -> List[str]:
        """Parse comma-separated list."""
        if not value or pd.isna(value):
            return []
        return [item.strip() for item in value.split(',')]
    
    def validate(self) -> List[str]:
        """Validate student data, return list of errors."""
        errors = []
        
        if not self.key:
            errors.append("Missing key")
        if not self.name:
            errors.append(f"Missing name for {self.key}")
        if not self.programme:
            errors.append(f"Missing programme for {self.key}")
        
        # Validate URL format
        if self.project_url and not re.match(r'https?://', self.project_url):
            errors.append(f"Invalid URL for {self.key}: {self.project_url}")
        
        return errors
    
    def check_assets(self) -> List[str]:
        """Check if all referenced assets exist."""
        errors = []
        
        if not self.photo.exists('student_images'):
            errors.append(f"Missing photo for {self.key}: {self.photo.name}")
        
        if not self.poster.exists('student_posters'):
            errors.append(f"Missing poster for {self.key}: {self.poster.name}")
        
        if not self.qr.exists('student_qr'):
            errors.append(f"Missing QR for {self.key}: {self.qr.name}")
        
        return errors
    
    def to_tex_dict(self) -> dict:
        """Convert to dictionary for template substitution."""
        return {
            '[Key]': self.key,
            '[SID]': self.sid,
            '[Name]': self.name,
            '[SortName]': self.sort_name,
            '[Programme]': self.programme,
            '[CommercialTitle]': self.commercial_title,
            '[AcademicTitle]': self.academic_title,
            '[Summary]': self.summary,
            '[Technologies]': ', '.join(self.technologies),
            '[ProjectURL]': self.project_url,
            '[SupervisorLabel]': self.supervisor_label,
            '[Supervisor]': self.supervisor,
            '[Room]': self.room,
            '[Number]': str(self.number),
            # ... add all fields
        }
```

**Updated generator**:

```python
def run(args):
    df = pd.read_csv("df_student_content.csv")
    template = open("latex/templates/student.tex").read()
    
    students = [Student.from_csv_row(row) for _, row in df.iterrows()]
    
    # Validate all students
    all_errors = []
    for student in students:
        errors = student.validate()
        errors.extend(student.check_assets())
        all_errors.extend(errors)
    
    if all_errors:
        for error in all_errors:
            print(f"ERROR: {error}")
        sys.exit(1)
    
    # Generate files
    for student in sorted(students, key=lambda s: s.sort_name):
        if args.verbose:
            print(f"{student.key:40} {student.name}")
        
        content = template
        for placeholder, value in student.to_tex_dict().items():
            content = content.replace(placeholder, latex_escape(value))
        
        with open(f"student_content/{student.key}.tex", "wt") as f:
            f.write(content)
```

**Benefits**:
- Type safety
- Self-documenting code
- Easier testing (can create Student objects directly)
- Validation logic co-located with data
- IDE autocomplete support

#### 3.2 Plugin Architecture for Formats (Priority: LOW)

**Problem**: Adding new output formats (HTML, Markdown) requires modifying core code.

**Solution**: Plugin system.

```python
# generators/base.py
from abc import ABC, abstractmethod

class Generator(ABC):
    """Base class for document generators."""
    
    @abstractmethod
    def generate_student_entry(self, student: Student) -> str:
        """Generate single student entry."""
        pass
    
    @abstractmethod
    def generate_programme(self, programme: str, students: List[Student]) -> str:
        """Generate programme section."""
        pass
    
    @abstractmethod
    def generate_document(self, students: List[Student]) -> str:
        """Generate complete document."""
        pass

# generators/latex.py
class LaTeXGenerator(Generator):
    def __init__(self, template_path: str):
        self.template = Path(template_path).read_text()
    
    def generate_student_entry(self, student: Student) -> str:
        content = self.template
        for placeholder, value in student.to_tex_dict().items():
            content = content.replace(placeholder, latex_escape(value))
        return content
    
    # ... implement other methods

# generators/html.py
class HTMLGenerator(Generator):
    """Generate HTML version of brochure."""
    
    def generate_student_entry(self, student: Student) -> str:
        return f"""
        <div class="student">
            <h2>{student.name}</h2>
            <h3>{student.commercial_title}</h3>
            <p>{student.summary}</p>
            <img src="student_images/{student.photo.name}.jpg" />
        </div>
        """
    
    # ... implement other methods

# Usage
generator = LaTeXGenerator("latex/templates/student.tex")
# or
generator = HTMLGenerator()

for student in students:
    output = generator.generate_student_entry(student)
```

**Benefits**:
- Can generate HTML for web viewing
- Can generate Markdown for GitHub
- Easy to add new formats
- Each generator is independently testable

#### 3.3 Database Backend (Priority: LOW)

**Problem**: CSV is hard to query, validate, and manage collaboratively.

**Solution**: SQLite database with CSV import/export.

```python
# database.py
import sqlite3
from typing import List

class BrochureDB:
    def __init__(self, db_path: str = "brochure.db"):
        self.conn = sqlite3.connect(db_path)
        self.create_schema()
    
    def create_schema(self):
        """Create database schema."""
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS students (
                key TEXT PRIMARY KEY,
                sid TEXT NOT NULL,
                name TEXT NOT NULL,
                sort_name TEXT NOT NULL,
                programme TEXT NOT NULL,
                commercial_title TEXT,
                academic_title TEXT,
                summary TEXT,
                technologies TEXT,
                project_url TEXT,
                supervisor_label TEXT,
                supervisor TEXT,
                room TEXT,
                number INTEGER
            )
        """)
        
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS project_areas (
                student_key TEXT,
                area TEXT,
                FOREIGN KEY (student_key) REFERENCES students(key)
            )
        """)
        
        # ... more tables
    
    def import_csv(self, csv_path: str):
        """Import students from CSV."""
        df = pd.read_csv(csv_path)
        for _, row in df.iterrows():
            student = Student.from_csv_row(row)
            self.add_student(student)
    
    def export_csv(self, csv_path: str):
        """Export students to CSV."""
        students = self.get_all_students()
        # Convert to DataFrame and save
    
    def add_student(self, student: Student):
        """Add student to database."""
        # Insert with proper SQL
    
    def get_students_by_programme(self, programme: str) -> List[Student]:
        """Get all students in a programme."""
        # Query database
    
    def validate_all(self) -> List[str]:
        """Run all validation checks."""
        # Check referential integrity, constraints, etc.
```

**Benefits**:
- Better data integrity (foreign keys, constraints)
- Easy queries (students by programme, area, supervisor)
- Can build web UI for data entry
- Audit trail (who changed what when)
- Concurrent access for multiple editors

**Drawback**: More complex, requires migration strategy

#### 3.4 Incremental Builds (Priority: LOW)

**Problem**: Full rebuild takes 5-10 minutes even for small changes.

**Solution**: Track dependencies and only rebuild changed files.

```python
import hashlib
from pathlib import Path
import json

class BuildCache:
    def __init__(self, cache_file=".build_cache.json"):
        self.cache_file = Path(cache_file)
        self.cache = self.load()
    
    def load(self):
        if self.cache_file.exists():
            return json.loads(self.cache_file.read_text())
        return {}
    
    def save(self):
        self.cache_file.write_text(json.dumps(self.cache, indent=2))
    
    def file_hash(self, path: Path) -> str:
        """Compute MD5 hash of file."""
        return hashlib.md5(path.read_bytes()).hexdigest()
    
    def needs_rebuild(self, source: Path, target: Path) -> bool:
        """Check if target needs rebuilding."""
        if not target.exists():
            return True
        
        source_hash = self.file_hash(source)
        cached_hash = self.cache.get(str(source))
        
        if source_hash != cached_hash:
            self.cache[str(source)] = source_hash
            return True
        
        return False

# Usage
cache = BuildCache()

for student in students:
    source = Path(f"student_content/{student.key}.tex")
    target = Path(f"student_content/{student.key}_content.tex")
    
    if cache.needs_rebuild(source, target):
        # Generate content file
        pass

cache.save()
```

**Benefits**:
- Much faster iteration
- Only process changed students
- Essential for weekly/daily builds

#### 3.5 Web-Based Admin Interface (Priority: LOW)

**Problem**: CSV editing is error-prone; requires technical knowledge.

**Solution**: Simple web UI for data entry.

```python
# app.py
from flask import Flask, render_template, request, redirect
from database import BrochureDB

app = Flask(__name__)
db = BrochureDB()

@app.route('/')
def index():
    students = db.get_all_students()
    return render_template('index.html', students=students)

@app.route('/student/add', methods=['GET', 'POST'])
def add_student():
    if request.method == 'POST':
        student = Student(
            key=request.form['key'],
            name=request.form['name'],
            # ... map form fields
        )
        db.add_student(student)
        return redirect('/')
    
    return render_template('add_student.html')

@app.route('/student/<key>/edit', methods=['GET', 'POST'])
def edit_student(key):
    # Edit form
    pass

@app.route('/export')
def export():
    db.export_csv('df_student_content.csv')
    return redirect('/')

@app.route('/build')
def build():
    # Trigger build process
    import subprocess
    subprocess.run(['make', 'all'])
    return redirect('/')
```

**Benefits**:
- Non-technical staff can enter data
- Form validation prevents errors
- Preview student entries
- Trigger builds from browser

**Drawback**: Requires web hosting, authentication, backup strategy

---

## 6. Prioritized Roadmap

### Immediate (Before Next Build)
**Effort**: 1-2 days

1. ✅ Add README.md (DONE)
2. Add input validation (1.1)
3. Add asset existence checks (1.2)
4. Cross-platform image processing (1.4)

**Impact**: Prevents 80% of build failures, enables non-macOS development

### Short-Term (Next 1-2 Months)
**Effort**: 1 week

1. Automatic LaTeX escaping (1.3)
2. Consolidate text processing in Python (2.1)
3. Configuration file (2.2)
4. Basic testing (2.3)
5. Better error messages (1.5)

**Impact**: Easier maintenance, fewer manual steps, testable code

### Medium-Term (Next 6 Months)
**Effort**: 2-3 weeks

1. Object-oriented redesign (3.1)
2. Logging and progress (2.5)
3. Sample data generation (2.4)
4. Incremental builds (3.4)

**Impact**: Professional codebase, faster iteration, easier onboarding

### Long-Term (If System Expands)
**Effort**: 4-6 weeks

1. Plugin architecture (3.2) - if HTML/web version needed
2. Database backend (3.3) - if multiple editors or complex queries needed
3. Web admin interface (3.5) - if non-technical data entry required

**Impact**: Future-proof, scalable to multiple departments/institutions

---

## 7. Risk Assessment

### Risks of NOT Improving

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Build failure late in process | High | High | Add validation (1.1, 1.2) |
| Platform lock-in (macOS only) | Medium | Medium | Fix image processing (1.4) |
| Knowledge loss (single maintainer) | High | High | Documentation + simplification |
| Data corruption (manual CSV editing) | Medium | High | Validation + backups |
| Cannot port to other departments | Low | Low | Accept limitation or refactor |

### Risks of Over-Engineering

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Complexity increases maintenance burden | High | Medium | Stick to Levels 1-2 |
| Features never used | Medium | Low | Build only what's needed |
| Team cannot maintain new codebase | Low | High | Keep Python simple, document well |

**Recommendation**: Focus on **Level 1 and Level 2** improvements. Only pursue Level 3 if:
- System used by multiple departments
- Built more than annually (monthly/weekly)
- Team expands beyond 1-2 maintainers
- Web/HTML output becomes requirement

---

## 8. Conclusion

### Summary Assessment

This is a **well-architected system for its use case** (annual brochure generation). The core design is sound:
- Data-driven approach ✅
- Automated build pipeline ✅
- Modular components ✅
- Professional output ✅

The main issues are **typical technical debt**:
- Minimal validation/error handling
- Platform dependencies
- Steep learning curve for maintainers
- Manual, error-prone steps

### Recommended Action Plan

**Phase 1 (Before next expo)**: Implement Level 1 quick wins
- Effort: 2-3 days
- ROI: Very high (prevents most build failures)

**Phase 2 (Next academic year)**: Implement Level 2 modest improvements
- Effort: 1-2 weeks
- ROI: High (easier maintenance, better code quality)

**Phase 3 (Only if needed)**: Consider Level 3 refactoring
- Effort: 4-6 weeks
- ROI: Medium (unless system scope expands significantly)

### Final Verdict

**Do not over-engineer this system.** The current architecture is appropriate for an annual process with 1-2 maintainers. Focus on:
1. **Validation** - fail fast with clear errors
2. **Portability** - remove macOS dependency
3. **Simplicity** - move complex shell logic to Python
4. **Documentation** - lower the learning curve

The system doesn't need microservices, Docker, CI/CD, or complex frameworks. It needs **boring, reliable, well-documented Python scripts** that "just work" once a year.

**Grade after improvements**: ⭐⭐⭐⭐⭐ (5/5) - Would be an exemplar of academic tooling done right.

---

**End of Review**
