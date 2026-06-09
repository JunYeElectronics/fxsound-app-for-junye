#!/usr/bin/env python3
"""
Regenerate BinaryData.cpp and BinaryData.h from .jucer resource definitions.
No Projucer needed — just run this script after replacing image/font/string files.

Usage:
    cd fxsound-app-for-junye
    python3 tools/regenerate_binary_data.py
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)  # fxsound-app-for-junye/
JUCER_PATH = os.path.join(REPO_ROOT, "fxsound", "FxSound.jucer")
OUTPUT_CPP = os.path.join(REPO_ROOT, "fxsound", "JuceLibraryCode", "BinaryData.cpp")
OUTPUT_H = os.path.join(REPO_ROOT, "fxsound", "JuceLibraryCode", "BinaryData.h")


def filename_to_identifier(filename: str) -> str:
    """Convert a filename to a C++ identifier matching Projucer's convention.

    Examples:
        Gilroy-Bold.ttf     -> GilroyBold_ttf
        logo-red.svg        -> logored_svg
        FxSound Black Bars.svg -> FxSound_Black_Bars_svg
        FxSound.ar.txt      -> FxSound_ar_txt
        FxSound.zh-CN.txt   -> FxSound_zhCN_txt
    """
    # Take just the basename (no path)
    name = os.path.basename(filename)
    # Replace spaces with underscores
    name = name.replace(" ", "_")
    # Remove hyphens
    name = name.replace("-", "")
    # Replace ALL dots with underscores (not just the extension)
    name = name.replace(".", "_")
    return name


def compute_hash(s: str) -> int:
    """Compute the Projucer hash (31 * hash + char) as unsigned 32-bit."""
    h = 0
    for ch in s:
        h = (31 * h + ord(ch)) & 0xFFFFFFFF
    return h


def parse_jucer_resources(jucer_path: str):
    """Parse .jucer file and return list of (resource_name, original_filename, file_path)."""
    tree = ET.parse(jucer_path)
    root = tree.getroot()
    jucer_dir = os.path.dirname(jucer_path)

    resources = []
    for file_elem in root.iter("FILE"):
        if file_elem.get("resource") == "1":
            name = file_elem.get("name")  # e.g. "logo-red.svg"
            rel_path = file_elem.get("file")  # e.g. "Images/logo-red.svg"
            abs_path = os.path.normpath(os.path.join(jucer_dir, rel_path))
            identifier = filename_to_identifier(name)
            resources.append((identifier, name, abs_path))

    return resources


def bytes_to_cpp_array(data: bytes, indent: str = "    ") -> str:
    """Convert binary data to a C++ byte array initializer."""
    parts = []
    for i in range(0, len(data), 16):
        chunk = data[i:i + 16]
        hex_vals = ",".join(f" {b}" for b in chunk)
        parts.append(f"{indent}{hex_vals},")
    return "\n".join(parts)


def generate_cpp(resources):
    """Generate BinaryData.cpp content."""
    lines = [
        "/* ==================================== JUCER_BINARY_RESOURCE ====================================",
        "",
        "   This is an auto-generated file: Any edits you make may be overwritten!",
        "",
        "*/",
        "",
        "namespace BinaryData",
        "{",
        "",
    ]

    # Generate byte arrays
    for i, (ident, orig_name, fpath) in enumerate(resources):
        with open(fpath, "rb") as f:
            data = f.read()
        lines.append(f"//================== {orig_name} ==================")
        lines.append(f"static const unsigned char temp_binary_data_{i}[] =")
        lines.append("{")
        lines.append(bytes_to_cpp_array(data))
        lines.append("};")
        lines.append("")

    # Generate named pointers
    for i, (ident, orig_name, fpath) in enumerate(resources):
        with open(fpath, "rb") as f:
            data = f.read()
        size = len(data)
        lines.append(f"const char* {ident} = (const char*) temp_binary_data_{i};")
        lines.append(f"const int   {ident}Size = {size};")
        lines.append("")

    # Generate getNamedResource
    lines.append('const char* getNamedResource (const char* resourceNameUTF8, int& numBytes);')
    lines.append('const char* getNamedResource (const char* resourceNameUTF8, int& numBytes)')
    lines.append('{')
    lines.append('    unsigned int hash = 0;')
    lines.append('')
    lines.append('    if (resourceNameUTF8 != nullptr)')
    lines.append('        while (*resourceNameUTF8 != 0)')
    lines.append('            hash = 31 * hash + (unsigned int) *resourceNameUTF8++;')
    lines.append('')
    lines.append('    switch (hash)')
    lines.append('    {')

    for ident, orig_name, fpath in resources:
        with open(fpath, "rb") as f:
            data = f.read()
        h = compute_hash(ident)
        size = len(data)
        lines.append(f'        case 0x{h:08x}:  numBytes = {size}; return {ident};')

    lines.append('        default: break;')
    lines.append('    }')
    lines.append('')
    lines.append('    numBytes = 0;')
    lines.append('    return nullptr;')
    lines.append('}')
    lines.append('')

    # Generate namedResourceList
    lines.append('const char* namedResourceList[] =')
    lines.append('{')
    for ident, _, _ in resources:
        lines.append(f'    "{ident}",')
    lines.append('};')
    lines.append('')

    # Generate originalFilenames
    lines.append('const char* originalFilenames[] =')
    lines.append('{')
    for _, orig_name, _ in resources:
        lines.append(f'    "{orig_name}",')
    lines.append('};')
    lines.append('')

    # Generate getNamedResourceOriginalFilename
    lines.append('const char* getNamedResourceOriginalFilename (const char* resourceNameUTF8);')
    lines.append('const char* getNamedResourceOriginalFilename (const char* resourceNameUTF8)')
    lines.append('{')
    lines.append('    for (unsigned int i = 0; i < (sizeof (namedResourceList) / sizeof (namedResourceList[0])); ++i)')
    lines.append('    {')
    lines.append('        if (namedResourceList[i] == resourceNameUTF8)')
    lines.append('            return originalFilenames[i];')
    lines.append('    }')
    lines.append('')
    lines.append('    return nullptr;')
    lines.append('}')
    lines.append('')
    lines.append('}')

    return "\n".join(lines)


def generate_header(resources):
    """Generate BinaryData.h content."""
    lines = [
        "/* =========================================================================================",
        "",
        "   This is an auto-generated file: Any edits you make may be overwritten!",
        "",
        "*/",
        "",
        "#pragma once",
        "",
        "namespace BinaryData",
        "{",
    ]

    for ident, orig_name, fpath in resources:
        with open(fpath, "rb") as f:
            data = f.read()
        size = len(data)
        lines.append(f"    extern const char*   {ident};")
        lines.append(f"    const int            {ident}Size = {size};")
        lines.append("")

    lines.append(f"    // Number of elements in the namedResourceList and originalFileNames arrays.")
    lines.append(f"    const int namedResourceListSize = {len(resources)};")
    lines.append("")
    lines.append("    // Points to the start of a list of resource names.")
    lines.append("    extern const char* namedResourceList[];")
    lines.append("")
    lines.append("    // Points to the start of a list of resource filenames.")
    lines.append("    extern const char* originalFilenames[];")
    lines.append("")
    lines.append("    // If you provide the name of one of the binary resource variables above, this function will")
    lines.append("    // return the corresponding data and its size (or a null pointer if the name isn't found).")
    lines.append("    const char* getNamedResource (const char* resourceNameUTF8, int& dataSizeInBytes);")
    lines.append("")
    lines.append("    // If you provide the name of one of the binary resource variables above, this function will")
    lines.append("    // return the corresponding original, non-mangled filename (or a null pointer if the name isn't found).")
    lines.append("    const char* getNamedResourceOriginalFilename (const char* resourceNameUTF8);")
    lines.append("}")

    return "\n".join(lines)


def main():
    if not os.path.exists(JUCER_PATH):
        print(f"ERROR: .jucer file not found: {JUCER_PATH}")
        sys.exit(1)

    resources = parse_jucer_resources(JUCER_PATH)
    print(f"Found {len(resources)} resources in {JUCER_PATH}")

    # Check all files exist
    missing = []
    for ident, orig_name, fpath in resources:
        if not os.path.exists(fpath):
            missing.append(f"  {orig_name} -> {fpath}")
    if missing:
        print(f"\nERROR: {len(missing)} resource files missing:")
        for m in missing:
            print(m)
        sys.exit(1)

    # Generate
    cpp_content = generate_cpp(resources)
    h_content = generate_header(resources)

    # Write
    os.makedirs(os.path.dirname(OUTPUT_CPP), exist_ok=True)
    with open(OUTPUT_CPP, "w", newline="\n") as f:
        f.write(cpp_content)
    print(f"Written: {OUTPUT_CPP} ({os.path.getsize(OUTPUT_CPP)} bytes)")

    with open(OUTPUT_H, "w", newline="\n") as f:
        f.write(h_content)
    print(f"Written: {OUTPUT_H} ({os.path.getsize(OUTPUT_H)} bytes)")

    print(f"\nDone! {len(resources)} resources regenerated.")
    print("Now compile x64 in Visual Studio.")


if __name__ == "__main__":
    main()
