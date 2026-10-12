#!/usr/bin/env python3
"""Validate real GNATdoc output, including repository-relative links and anchors.

Uses only Python's standard library; does not fetch external URLs.
"""

import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.links = []
        self.ids = set()
        self.text = []
        self.feed(path.read_text(encoding="utf-8"))

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        for key in ("href", "src"):
            if attrs.get(key):
                self.links.append(attrs[key])
        for key in ("id", "name"):
            if attrs.get(key):
                self.ids.add(attrs[key])

    def handle_data(self, data):
        self.text.append(data)


def validate(site):
    site = site.resolve()
    root = Path(__file__).resolve().parent.parent
    pages = {p.resolve(): Page(p) for p in site.rglob("*.html")}
    errors = []
    for required in (site / "index.html", site / "api/index.html",
                     site / "api/gnatdoc.css"):
        if not required.is_file() or required.stat().st_size == 0:
            errors.append(f"missing/empty: {required.relative_to(site)}")
    for path, page in pages.items():
        for link in page.links:
            url = urlsplit(link)
            if url.scheme in ("https", "http", "mailto"):
                continue
            if url.scheme or url.netloc or url.path.startswith("/"):
                errors.append(f"non-relative local link in {path.name}: {link}")
                continue
            target = (path.parent / unquote(url.path)).resolve() if url.path else path
            if not target.is_relative_to(site) or not target.is_file():
                errors.append(f"broken link in {path.name}: {link}")
            elif url.fragment and target in pages:
                if unquote(url.fragment) not in pages[target].ids:
                    errors.append(f"missing anchor in {path.name}: {link}")
        text = " ".join(page.text)
        if re.search(r"OpenCV\.Internal|Opencv_Core_Config|/home/|/workspace/|file://", text, re.I):
            errors.append(f"internal unit or machine-local path in {path.name}")
    # GNATdoc 26 uses hashed filenames. Resolve package pages from native h1
    # headings instead of inventing filenames or synthesizing API pages.
    packages = {}
    for path, page in pages.items():
        source = path.read_text(encoding="utf-8")
        match = re.search(r"<h1>([^<]+)</h1>", source)
        if match:
            packages[match[1]] = (path, " ".join(page.text))
    expected = set()
    for spec in (root / "src").glob("*.ads"):
        match = re.search(r"\bpackage\s+([\w.]+)\s+is\b", spec.read_text(), re.I)
        if match:
            expected.add(match[1].lower())
    actual = {name.lower() for name in packages}
    for name in sorted(expected - actual):
        errors.append(f"public package missing: {name}")
    probes = {
        "OpenCV": ("Point_3D", "Rotated_Rect", "Make_Scalar"),
        "OpenCV.Core": ("Mat", "UMat", "Add", "Cart_To_Polar", "Transpose"),
        "OpenCV.Core.Transfers": ("To_UMat", "To_Mat"),
        "OpenCV.Core.Persistence": ("File_Storage", "Open_Memory", "Read_Integer"),
        "OpenCV.Core.Sparse": ("Sparse_Mat", "Convert_To", "Normalize"),
        "OpenCV.Core.Fixed_Matrices": ("Element_Type", "Row_Count", "Matrix"),
        "OpenCV.Core.Vectors": ("Element_Type", "Vector"),
        "OpenCV.Core.UInt8_Access": ("OpenCV.Core",),
        "OpenCV.Core.UInt8_Mat_View": ("With_Writable_Mat_View",),
    }
    for name, declarations in probes.items():
        text = packages.get(name, (None, ""))[1]
        for declaration in declarations:
            if declaration not in text:
                errors.append(f"missing representative declaration: {name}.{declaration}")
    formal_text = {
        "OpenCV.Core.Fixed_Matrices": (
            "Type of each matrix element.", "Number of rows. Must be positive.",
            "Number of columns. Must be positive.",
            "does not introduce an OpenCV native handle of its own"),
        "OpenCV.Core.Vectors": (
            "Type of each vector element.", "Number of components. Must be positive.",
            "does not introduce an OpenCV native handle of its own"),
    }
    for name, phrases in formal_text.items():
        text = " ".join(packages.get(name, (None, ""))[1].split())
        for phrase in phrases:
            if phrase not in text:
                errors.append(f"generic documentation did not render: {name}: {phrase}")
    core_path = packages.get("OpenCV.Core", (None, ""))[0]
    if core_path:
        core_html = core_path.read_text(encoding="utf-8")
        overloads = re.findall(r"<h4 id=([^ >]+)>Add</h4>", core_html)
        if len(set(overloads)) < 4:
            errors.append("Mat/UMat Add overloads lack distinct native anchors")
        # Inspect each declaration's own section (from its native heading and
        # declaration snippet to the next declaration), not the whole page.
        sections = {}
        for match in re.finditer(
                r"<h4 id=[^ >]+>([^<]+)</h4><pre class=ada-code-snippet><code>"
                r"(.*?)</code></pre>(.*?)(?=<h4 id=|$)", core_html, re.S):
            code = " ".join(match[2].split())
            sections[code.split(" is")[0].split(" (")[0]] = (
                " ".join(re.sub(r"<[^>]+>", " ", match[3]).split()))
        core_docs = {
            "type Depth_Type": ("UInt8 Unsigned 8-bit integer channel values",
                                "Float16 IEEE binary16", "not a value-range"),
            "type Reduction_Axis": ("Across_Rows Combines the rows of each column",
                                    "Across_Columns Combines the columns of each row"),
            "type Covariance_Scaling": ("Unscaled", "By_Sample_Count",
                                        "not the 1/(N - 1) estimator"),
            "type Region_Location": ("Whole_Size Extent of the original allocation",
                                     "Offset Zero-based location"),
            "type Dimension_Selection": ("Kind Selects the variant",
                                         "Bounds Zero-based half-open",
                                         "Index Zero-based index selected",
                                         "never holds both"),
            "type Mat_Type": ("Depth Storage depth", "Channels Number of channels"),
            "type ND_Min_Max_Result": ("Has_Minimum True when",
                                       "Dimensions Number of source dimensions",
                                       "not an extremum"),
            "type Range_Check_Result": ("Valid True when no invalid element",
                                        "First_Invalid Zero-based location",
                                        "Present only when Valid is False"),
            "type Mat": ("Ada assignment is shallow", "Clone makes an explicit deep copy"),
            "type UMat": ("not guaranteed to be active", "Clone makes an explicit deep copy"),
        }
        for declaration, phrases in core_docs.items():
            section = sections.get(declaration)
            if section is None:
                errors.append(f"OpenCV.Core declaration section missing: {declaration}")
                continue
            for phrase in phrases:
                if phrase not in section:
                    errors.append(f"OpenCV.Core {declaration} lacks rendered text: {phrase}")
    transfers_text = packages.get("OpenCV.Core.Transfers", (None, ""))[1]
    if "Explicit independent copies" not in transfers_text:
        errors.append("representative source comment did not render")
    if errors:
        raise SystemExit("\n".join(errors))
    print(f"Validated {len(expected)} public packages, {len(pages)} HTML pages; "
          "all local links, anchors and assets resolve under /opencv_core_ada/.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: validate_docs.py SITE_DIRECTORY")
    validate(Path(sys.argv[1]))