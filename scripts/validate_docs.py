#!/usr/bin/env python3
"""Validate real GNATdoc output, including repository-relative links and anchors.

Uses only Python's standard library; does not fetch external URLs.
"""

import html
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


def overload_sections(core_html):
    """Map each OpenCV.Core subprogram to its own native GNATdoc section.

    The key is the complete normalized declaration (name, parameters, and
    return profile), never the bare name, so overloads cannot satisfy one
    another's checks. Returns (sections, errors); section values are
    (native anchor, rendered section text).
    """
    sections, errors, anchors = {}, [], {}
    for match in re.finditer(
            r"<h4 id=([^ >]+)>[^<]+</h4><pre class=ada-code-snippet><code>"
            r"(.*?)</code></pre>(.*?)(?=<h4 id=|$)", core_html, re.S):
        signature = " ".join(html.unescape(re.sub(r"<[^>]+>", "", match[2])).split())
        if not signature.startswith(("function ", "procedure ")):
            continue
        signature = signature.replace("( ", "(").replace(" )", ")")
        text = " ".join(html.unescape(re.sub(r"<[^>]+>", " ", match[3])).split())
        if signature in sections:
            errors.append(f"duplicate OpenCV.Core declaration section: {signature}")
        if match[1] in anchors:
            errors.append(f"shared native anchor for {signature} and {anchors[match[1]]}")
        anchors[match[1]] = signature
        sections[signature] = (match[1], text)
    return sections, errors


# Complete declaration -> text that must render inside that declaration's own
# section: leading prose, parameter descriptions, and return descriptions.
LIFECYCLE_DOCS = {
    "function Create (Rows, Columns : Natural; Element_Type : Mat_Type) return Mat": (
        "typed, zero-extent Mat", "Rows Number of rows", "Columns Number of columns",
        "Element_Type Depth and channel count", "Return Value A new Mat that owns"),
    "function Create (Dimensions : Size; Element_Type : Mat_Type) return Mat": (
        "Height gives the row count", "Dimensions Width (columns) and Height (rows)",
        "Return Value A new Mat that owns"),
    "function Create (Shape : Dimension_Array; Element_Type : Mat_Type) return Mat": (
        "10 on OpenCV 5.0", "Shape Extent of each dimension",
        "Return Value A new N-dimensional Mat"),
    "function Create_UMat (Rows, Columns : Natural; Element_Type : Mat_Type) "
    "return UMat": (
        "not guaranteed to be resident on a GPU", "Rows Number of rows",
        "Return Value A new UMat that owns"),
    "function Create_UMat (Shape : Dimension_Array; Element_Type : Mat_Type) "
    "return UMat": (
        "OpenCV 5 accepts at most 10 dimensions", "Shape Extent of each dimension",
        "Return Value A new UMat that owns"),
    "function Clone (Self : Mat) return Mat": (
        "independent deep copy", "Self The Mat to copy.",
        "Return Value A new Mat with independent"),
    "function Clone (Self : UMat) return UMat": (
        "independent deep copy", "Self The UMat to copy.",
        "Return Value A new UMat with independent"),
    "procedure Copy_To (Self : Mat; Destination : in out Mat)": (
        "Exact self-copy is supported",
        "Destination The caller-owned Mat that receives the elements."),
    "procedure Copy_To (Self : Mat; Destination : in out Mat; Mask : Mat)": (
        "Unselected elements retain their values", "Mask UInt8 single-channel Mat"),
    "function Copy_To (Self : UMat) return UMat": (
        "not symmetrical", "Self The UMat to copy.",
        "Return Value A new UMat holding a copy"),
    "function Convert_To (Self : Mat; Depth : Depth_Type; Scale : Long_Float := 1.0; "
    "Offset : Long_Float := 0.0) return Mat": (
        "aliasing does not apply", "Scale Factor applied",
        "Offset Value added after scaling.",
        "Return Value A new Mat of the requested depth."),
    "function Convert_To (Self : UMat; Depth : Depth_Type; Scale : Long_Float := 1.0; "
    "Offset : Long_Float := 0.0) return UMat": (
        "owns independent storage", "Depth Depth of the result.",
        "Return Value A new UMat of the requested depth."),
    "procedure Convert_To (Self : Mat; Destination : in out Mat; Depth : Depth_Type; "
    "Scale : Long_Float := 1.0; Offset : Long_Float := 0.0)": (
        "rejected as destinations",
        "Destination The caller-owned Mat that receives the result."),
    "procedure Convert_To (Self : UMat; Destination : in out UMat; Depth : Depth_Type; "
    "Scale : Long_Float := 1.0; Offset : Long_Float := 0.0)": (
        "arbitrary partially overlapping views are not supported",
        "Destination The caller-owned UMat that receives the result."),
}

METADATA_REGION_DOCS = {
    "function Shape (Self : Mat) return Dimension_Array": (
        "Dimensions remains the 2-D Size view",
        "Return Value The extents of all dimensions, in native"),
    "function Shape (Self : UMat) return Dimension_Array": (
        "returns a null array", "Return Value The extents of all dimensions."),
    "function Dimension_Count (Self : Mat) return Natural": (
        "A genuine default empty Mat reports 0", "Return Value The number of dimensions."),
    "function Dimension_Count (Self : UMat) return Natural": (
        "A default UMat reports 0", "Return Value The dimension count."),
    "function Total (Self : Mat) return Mat_Size": (
        "neither a scalar count nor a byte count", "Return Value The number of elements."),
    "function Total (Self : UMat) return Mat_Size": (
        "not a byte count", "Return Value The number of elements."),
    "function Element_Size (Self : Mat) return Mat_Size": (
        "one complete element", "Return Value The byte size of one element."),
    "function Element_Size (Self : UMat) return Mat_Size": (
        "one complete element", "Return Value The byte size of one element."),
    "function Channel_Size (Self : Mat) return Mat_Size": (
        "one channel of an element", "Return Value The byte size of one channel."),
    "function Channel_Size (Self : UMat) return Mat_Size": (
        "one channel of an element", "Return Value The byte size of one channel."),
    "function Region (Self : Mat; Area : Rect) return Mat": (
        "callback-scoped temporary external Mat view", "Area Zero-based rectangle",
        "Return Value A new Mat header that may share"),
    "function Region (Self : UMat; Area : Rect) return UMat": (
        "without host mapping", "Area Zero-based rectangle",
        "Return Value A new UMat header that may share"),
    "function Slice (Self : Mat; Ranges : Index_Range_Array) return Mat": (
        "not necessarily contiguous", "Ranges One zero-based half-open range",
        "Return Value A new Mat header that may share"),
    "function Slice (Self : UMat; Ranges : Index_Range_Array) return UMat": (
        "not necessarily contiguous", "Ranges One zero-based half-open range",
        "Return Value A new UMat header that may share"),
    "function Locate_Region (Self : Mat) return Region_Location": (
        "not an allocation identity", "Return Value Whole-allocation size"),
    "function Locate_Region (Self : UMat) return Region_Location": (
        "not an allocation identity", "Return Value Whole-allocation size"),
    "procedure Adjust_Region (Self : in out Mat; "
    "Top, Bottom, Left, Right : Region_Adjustment)": (
        "NOT recomputed", "Top Adjustment of the top boundary.",
        "Right Adjustment of the right boundary."),
    "procedure Adjust_Region (Self : in out UMat; "
    "Top, Bottom, Left, Right : Region_Adjustment)": (
        "not a reliable indicator", "Top Adjustment of the top boundary.",
        "Right Adjustment of the right boundary."),
}


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
        # Overload-aware checks: complete signatures and native anchors, so one
        # overload's text can never satisfy a different overload's check.
        overloads, overload_errors = overload_sections(core_html)
        errors.extend(overload_errors)
        for table in (LIFECYCLE_DOCS, METADATA_REGION_DOCS):
            for signature, phrases in table.items():
                if signature not in overloads:
                    errors.append(f"OpenCV.Core overload section missing: {signature}")
                    continue
                for phrase in phrases:
                    if phrase not in overloads[signature][1]:
                        errors.append(
                            f"OpenCV.Core {signature} lacks rendered text: {phrase}")
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