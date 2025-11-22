#!/usr/bin/env python3
"""
Doxygen XML → Docusaurus Markdown Converter
Unterstützt: Sections, Tabellen, Mermaid-Diagramme, @verbatim
"""

import argparse
import json
import re
import xml.etree.ElementTree as ET
from html import unescape
from pathlib import Path
from typing import Any, Dict, List, Optional, Set


class DoxygenLayoutParser:
    """Parst DoxygenLayout.xml für Navigation"""

    def __init__(self, layout_file: Path):
        self.layout_file = layout_file

    def parse_navigation(self) -> List[Dict[str, Any]]:
        if not self.layout_file.exists():
            return []

        tree = ET.parse(self.layout_file)
        root = tree.getroot()

        navigation: List[Dict[str, Any]] = []
        navindex = root.find('.//navindex')
        if navindex is None:
            return navigation

        for tab in navindex.findall('tab'):
            if tab.get('visible', 'yes') == 'yes':
                nav_item = self._parse_tab(tab)
                if nav_item:
                    navigation.append(nav_item)

        return navigation

    def _parse_tab(self, tab) -> Optional[Dict[str, Any]]:
        tab_type = tab.get('type', 'user')
        title = tab.get('title', '')
        url = tab.get('url', '')

        ref_match = re.search(r'@ref\s+(\w+)', url)
        group_ref = ref_match.group(1) if ref_match else None

        subtabs: List[Dict[str, Any]] = []
        for subtab in tab.findall('tab'):
            sub_item = self._parse_tab(subtab)
            if sub_item:
                subtabs.append(sub_item)

        return {
            'type': tab_type,
            'title': title,
            'group_ref': group_ref,
            'subtabs': subtabs,
        }


class DoxygenXMLParser:
    """Parst Doxygen XML Dateien"""

    def __init__(self, xml_dir: Path):
        self.xml_dir = xml_dir
        self.groups: Dict[str, Dict[str, Any]] = {}
        self.index_content: Optional[Dict[str, str]] = None
        self._processed_para_ids: Set[int] = set()

    def parse(self):
        print("📖 Parsing Doxygen XML...")

        self._parse_index()

        group_files = list(self.xml_dir.glob("group__*.xml"))
        for xml_file in group_files:
            self._parse_group(xml_file)

        print(f"   ✅ Parsed {len(self.groups)} groups")

    def _parse_index(self):
        for filename in ['indexpage.xml', 'index.xml']:
            index_file = self.xml_dir / filename
            if index_file.exists():
                tree = ET.parse(index_file)
                compound = tree.find('.//compounddef[@kind="page"]')

                if compound is not None:
                    title = compound.findtext('title', 'API Documentation')

                    self._processed_para_ids.clear()
                    brief = self._get_description_all(compound.find('briefdescription'))

                    self._processed_para_ids.clear()
                    detailed = self._get_description_all(compound.find('detaileddescription'))

                    self.index_content = {
                        'title': title,
                        'brief': brief,
                        'detailed': detailed,
                    }
                    return

    def _parse_group(self, xml_file: Path):
        try:
            tree = ET.parse(xml_file)
            compound = tree.find('.//compounddef[@kind="group"]')

            if compound is None:
                return

            name = compound.findtext('compoundname', '')
            title = compound.findtext('title', name)

            self._processed_para_ids.clear()
            brief = self._get_description_direct(compound.find('briefdescription'))

            self._processed_para_ids.clear()
            detailed = self._get_description_with_sections(compound.find('detaileddescription'))

            innergroups = []
            for ig in compound.findall('.//innergroup'):
                innergroups.append({
                    'refid': ig.get('refid'),
                    'name': ig.text,
                })

            functions = []
            typedefs = []
            enums = []
            defines = []

            for memberdef in compound.findall('.//memberdef'):
                kind = memberdef.get('kind')

                if kind == 'function':
                    func = self._parse_function(memberdef)
                    if func:
                        functions.append(func)
                elif kind == 'typedef':
                    typedef = self._parse_typedef(memberdef)
                    if typedef:
                        typedefs.append(typedef)
                elif kind == 'enum':
                    enum = self._parse_enum(memberdef)
                    if enum:
                        enums.append(enum)
                elif kind == 'define':
                    define = self._parse_define(memberdef)
                    if define:
                        defines.append(define)

            self.groups[name] = {
                'title': title,
                'brief': brief,
                'detailed': detailed,
                'innergroups': innergroups,
                'functions': functions,
                'typedefs': typedefs,
                'enums': enums,
                'defines': defines,
            }

        except Exception as e:
            print(f"   ⚠️  Warning: Could not parse {xml_file.name}: {e}")

    def _get_description_with_sections(self, elem) -> str:
        if elem is None:
            return ""

        parts: List[str] = []

        for para in elem.findall('./para'):
            para_id = id(para)
            if para_id not in self._processed_para_ids:
                self._processed_para_ids.add(para_id)
                text = self._parse_para(para)
                if text:
                    parts.append(text)

        for sect1 in elem.findall('./sect1'):
            section_parts = self._parse_section(sect1, level=2)
            if section_parts:
                parts.append(section_parts)

        return '\n\n'.join(parts)

    def _parse_section(self, sect_elem, level: int = 2) -> str:
        parts: List[str] = []

        title_elem = sect_elem.find('./title')
        if title_elem is not None:
            title_text = ''.join(title_elem.itertext()).strip()
            if title_text:
                heading = '#' * level
                parts.append(f"{heading} {title_text}")

        for para in sect_elem.findall('./para'):
            para_id = id(para)
            if para_id not in self._processed_para_ids:
                self._processed_para_ids.add(para_id)
                text = self._parse_para(para)
                if text:
                    parts.append(text)

        for subsect in sect_elem.findall('./sect2'):
            subsection_text = self._parse_section(subsect, level=level + 1)
            if subsection_text:
                parts.append(subsection_text)

        for subsect in sect_elem.findall('./sect3'):
            subsection_text = self._parse_section(subsect, level=level + 1)
            if subsection_text:
                parts.append(subsection_text)

        return '\n\n'.join(parts)

    def _get_description_all(self, elem) -> str:
        if elem is None:
            return ""

        parts: List[str] = []
        for para in elem.findall('.//para'):
            para_id = id(para)

            if para_id in self._processed_para_ids:
                continue

            self._processed_para_ids.add(para_id)

            text = self._parse_para(para)
            if text:
                parts.append(text)

        return '\n\n'.join(parts)

    def _get_description_direct(self, elem) -> str:
        if elem is None:
            return ""

        parts: List[str] = []
        for para in elem.findall('./para'):
            para_id = id(para)

            if para_id in self._processed_para_ids:
                continue

            self._processed_para_ids.add(para_id)

            text = self._parse_para(para)
            if text:
                parts.append(text)

        return '\n\n'.join(parts)

    def _parse_para(self, para) -> str:
        result: List[str] = []

        # 1. Check for <verbatim> tags (generated by @verbatim in Doxygen)
        has_verbatim = para.find('.//verbatim') is not None
        
        if has_verbatim:
            if para.text and para.text.strip():
                result.append(para.text.strip())

            for child in para:
                if child.tag == 'verbatim':
                    # Verbatim content is directly in .text, whitespace is preserved by XML parser
                    code_block = child.text or ""
                    
                    if self._is_mermaid(code_block):
                        code_block = self._normalize_mermaid(code_block)
                        result.append(f"\n```mermaid\n{code_block}\n```\n")
                    else:
                        result.append(f"\n```\n{code_block}\n```\n")
                
                # Handle tail text (text after the verbatim block)
                if child.tail and child.tail.strip():
                    result.append(child.tail.strip())

            return '\n\n'.join(result).strip()

        # 2. Check for @mermaid text blocks (if not wrapped in verbatim/code)
        # This is a fallback for when @mermaid is written directly in text
        full_text = ''.join(para.itertext())
        mermaid_match = re.search(r'@mermaid\s*(.*?)\s*@endmermaid', full_text, re.DOTALL | re.IGNORECASE)

        if mermaid_match:
            mermaid_code = self._normalize_mermaid(mermaid_match.group(1))
            pre_text = full_text[:mermaid_match.start()].strip()
            if pre_text:
                result.append(pre_text)

            result.append(f"\n```mermaid\n{mermaid_code}\n```\n")

            post_text = full_text[mermaid_match.end():].strip()
            if post_text:
                result.append(post_text)

            return '\n\n'.join(result).strip()

        has_itemizedlist = para.find('.//itemizedlist') is not None
        has_table = para.find('.//table') is not None
        has_programlisting = para.find('.//programlisting') is not None

        if has_programlisting:
            if para.text and para.text.strip():
                result.append(para.text.strip())

            for child in para:
                if child.tag == 'programlisting':
                    code_block = self._programlisting_to_code(child)

                    if self._is_mermaid(code_block):
                        code_block = self._normalize_mermaid(code_block)
                        result.append(f"\n```mermaid\n{code_block}\n```\n")
                    else:
                        lang = self._detect_programlisting_language(child)
                        result.append(f"\n```{lang}\n{code_block}\n```\n")

                if child.tail and child.tail.strip():
                    result.append(child.tail.strip())

            return '\n\n'.join(result).strip()

        if has_table:
            if para.text and para.text.strip():
                result.append(para.text.strip())

            for child in para:
                if child.tag == 'table':
                    table_md = self._parse_table(child)
                    if table_md:
                        result.append('\n\n' + table_md + '\n')

                if child.tail and child.tail.strip():
                    result.append(child.tail.strip())

            return '\n\n'.join(result).strip()

        if has_itemizedlist:
            if para.text and para.text.strip():
                result.append(para.text.strip())

            for child in para:
                if child.tag == 'itemizedlist':
                    items = []
                    for listitem in child.findall('.//listitem'):
                        listitem_para = listitem.find('.//para')
                        if listitem_para is not None:
                            self._processed_para_ids.add(id(listitem_para))

                        item_text = self._extract_text_only(listitem)
                        if item_text:
                            items.append(f"- {item_text}")

                    if items:
                        result.append('\n\n' + '\n'.join(items) + '\n')

                if child.tail and child.tail.strip():
                    result.append(child.tail.strip())

            return '\n\n'.join(result).strip()

        if para.text and para.text.strip():
            result.append(para.text.strip())

        for child in para:
            if child.tag == 'ref':
                text = child.text or ''
                result.append(f"`{text}`")
            elif child.tag == 'computeroutput':
                code = ''.join(child.itertext())
                result.append(f"`{code}`")
            elif child.tag == 'bold':
                text = ''.join(child.itertext())
                result.append(f"**{text}**")
            elif child.tag == 'emphasis':
                text = ''.join(child.itertext())
                result.append(f"*{text}*")
            elif child.tag == 'simplesect':
                kind = child.get('kind', '')
                if kind in ['note', 'warning', 'see']:
                    sect_title = kind.capitalize()
                    sect_content = self._parse_simplesect(child)
                    if sect_content:
                        result.append(f"\n\n**{sect_title}:** {sect_content}\n")

            if child.tail and child.tail.strip():
                result.append(child.tail.strip())

        return ' '.join(filter(None, result)).strip()

    def _programlisting_to_code(self, programlisting) -> str:
        """Extract code from programlisting - preserve spaces in lines"""
        lines = []
        for codeline in programlisting.findall('./codeline'):
            # Use helper to preserve whitespace nodes like <sp> and <tab>
            text = self._node_to_text_preserving_whitespace(codeline)
            lines.append(text)
        return '\n'.join(lines).strip('\n')

    def _node_to_text_preserving_whitespace(self, element) -> str:
        """Recursively extract text while preserving <sp> and <tab> tags"""
        parts = []
        if element.text:
            parts.append(element.text)
        
        for child in element:
            if child.tag == 'sp':
                parts.append(' ')
            elif child.tag == 'tab':
                parts.append('\t')
            elif child.tag == 'linebreak':
                parts.append('\n')
            else:
                # Recursive call for other tags (highlight, ref, etc.)
                parts.append(self._node_to_text_preserving_whitespace(child))
            
            if child.tail:
                parts.append(child.tail)
        
        text = "".join(parts)
        text = unescape(text)
        # Only replace non-breaking spaces with normal spaces
        text = text.replace('\xa0', ' ').replace('\u2009', ' ').replace('\u202f', ' ')
        return text

    def _detect_programlisting_language(self, programlisting) -> str:
        filename = programlisting.get('filename', '') or ''
        ext = Path(filename).suffix.lower()
        mapping = {
            '.yml': 'yaml',
            '.yaml': 'yaml',
            '.txt': 'text',
            '.sh': 'bash',
            '.json': 'json',
            '.py': 'python',
            '.md': 'markdown',
        }
        return mapping.get(ext, 'c')

    def _is_mermaid(self, code_block: str) -> bool:
        """Check if code block contains Mermaid syntax"""
        patterns = [
            r'\bgraph\s+(TD|LR|RL|BT|TB)\b',
            r'\bsequenceDiagram\b',
            r'\bclassDiagram\b',
            r'\bstateDiagram\b',
            r'\berDiagram\b',
            r'\bgantt\b',
            r'\bpie\b',
            r'\bflowchart\b',
            r'\bjourney\b',
            r'\bgitGraph\b',
            r'\bC4(?:Context|Container|Component|Dynamic)\b',
            r'\bmindmap\b',
            r'\btimeline\b',
        ]
        return any(re.search(pattern, code_block, re.IGNORECASE) for pattern in patterns)

    def _normalize_mermaid(self, code_block: str) -> str:
        """Normalize Mermaid code - preserve spaces in labels"""
        # Replace non-breaking spaces
        code_block = code_block.replace('\xa0', ' ')
        
        # Process line by line to preserve spaces
        lines = []
        for line in code_block.split('\n'):
            # Remove leading asterisks from Doxygen comments
            cleaned = re.sub(r'^\s*\*\s?', '', line)
            # Remove only trailing whitespace, keep internal spaces
            cleaned = cleaned.rstrip()
            if cleaned:  # Skip empty lines
                lines.append(cleaned)
        
        code_block = '\n'.join(lines)
        
        # Normalize graph direction (case-insensitive)
        code_block = re.sub(
            r'\bgraph\s+(TD|LR|RL|BT|TB)\b',
            lambda m: f"graph {m.group(1).upper()}",
            code_block,
            flags=re.IGNORECASE,
        )
        
        # Normalize style statements (preserve content after 'style')
        # Only ensure single space after node identifier
        code_block = re.sub(
            r'\bstyle\s+([A-Za-z0-9_]+)\s+',
            r'style \1 ',
            code_block,
        )
        
        return code_block.strip('\n')

    def _parse_table(self, table_elem) -> str:
        rows: List[List[str]] = []

        for row_elem in table_elem.findall('.//row'):
            cells: List[str] = []
            for entry in row_elem.findall('./entry'):
                cell_parts: List[str] = []
                for para in entry.findall('.//para'):
                    text = ''.join(para.itertext()).strip()
                    if text:
                        cell_parts.append(text)

                cell_text = ' '.join(cell_parts) if cell_parts else ''
                cells.append(cell_text)

            if cells:
                rows.append(cells)

        if not rows:
            return ""

        header = rows[0]
        md_lines = [
            '| ' + ' | '.join(header) + ' |',
            '|' + '|'.join(['---' for _ in header]) + '|',
        ]

        for row in rows[1:]:
            while len(row) < len(header):
                row.append('')
            md_lines.append('| ' + ' | '.join(row) + ' |')

        return '\n'.join(md_lines)

    def _parse_simplesect(self, simplesect) -> str:
        parts: List[str] = []
        for para in simplesect.findall('.//para'):
            para_id = id(para)
            if para_id not in self._processed_para_ids:
                self._processed_para_ids.add(para_id)
                text = self._parse_para(para)
                if text:
                    parts.append(text)
        return ' '.join(parts)

    def _extract_text_only(self, elem) -> str:
        text_parts: List[str] = []

        para = elem.find('.//para')
        if para is None:
            return ""

        if para.text and para.text.strip():
            text_parts.append(para.text.strip())

        for child in para:
            if child.text and child.text.strip():
                text_parts.append(child.text.strip())
            if child.tail and child.tail.strip():
                text_parts.append(child.tail.strip())

        return ' '.join(text_parts).strip()

    def _parse_function(self, elem) -> Optional[Dict[str, Any]]:
        try:
            name = elem.findtext('name', '')
            definition = elem.findtext('definition', '')
            argsstring = elem.findtext('argsstring', '')

            self._processed_para_ids.clear()
            brief = self._get_description_direct(elem.find('briefdescription'))

            self._processed_para_ids.clear()
            detailed = self._get_description_direct(elem.find('detaileddescription'))

            params = []
            for param in elem.findall('.//param'):
                param_type_elem = param.find('type')
                param_type = ''.join(param_type_elem.itertext()) if param_type_elem is not None else ''
                param_name = param.findtext('declname', '')

                param_desc = ''
                for paramlist in elem.findall('.//parameterlist[@kind="param"]'):
                    for paramitem in paramlist.findall('parameteritem'):
                        paramname = paramitem.find('.//parametername')
                        if paramname is not None and paramname.text == param_name:
                            self._processed_para_ids.clear()
                            param_desc = self._get_description_direct(paramitem.find('.//parameterdescription'))

                params.append({
                    'type': param_type,
                    'name': param_name,
                    'description': param_desc,
                })

            return_desc = ''
            for simplesect in elem.findall('.//simplesect[@kind="return"]'):
                self._processed_para_ids.clear()
                return_desc = self._get_description_direct(simplesect)

            return {
                'name': name,
                'signature': f"{definition}{argsstring}",
                'brief': brief,
                'detailed': detailed,
                'params': params,
                'return': return_desc,
            }
        except Exception:
            return None

    def _parse_typedef(self, elem) -> Optional[Dict[str, str]]:
        try:
            self._processed_para_ids.clear()
            return {
                'name': elem.findtext('name', ''),
                'definition': elem.findtext('definition', ''),
                'brief': self._get_description_direct(elem.find('briefdescription')),
            }
        except Exception:
            return None

    def _parse_enum(self, elem) -> Optional[Dict[str, Any]]:
        try:
            values = []
            for val in elem.findall('.//enumvalue'):
                self._processed_para_ids.clear()
                values.append({
                    'name': val.findtext('name', ''),
                    'initializer': val.findtext('initializer', ''),
                    'brief': self._get_description_direct(val.find('briefdescription')),
                })

            self._processed_para_ids.clear()
            return {
                'name': elem.findtext('name', ''),
                'brief': self._get_description_direct(elem.find('briefdescription')),
                'values': values,
            }
        except Exception:
            return None

    def _parse_define(self, elem) -> Optional[Dict[str, str]]:
        try:
            self._processed_para_ids.clear()
            return {
                'name': elem.findtext('name', ''),
                'value': elem.findtext('initializer', ''),
                'brief': self._get_description_direct(elem.find('briefdescription')),
            }
        except Exception:
            return None


class DocusaurusMarkdownGenerator:
    """Generiert Docusaurus Markdown"""

    def __init__(self, output_dir: Path):
        self.output_dir = output_dir

    def generate(self, navigation: List[Dict[str, Any]], groups: Dict[str, Dict[str, Any]], index_content: Optional[Dict[str, str]]):
        print("📝 Generating Docusaurus Markdown...")

        self.output_dir.mkdir(parents=True, exist_ok=True)

        if index_content:
            self._write_index(index_content, navigation, groups)

        for group_name, group_data in groups.items():
            self._write_group(group_name, group_data)

        self._write_sidebars(navigation, groups)

        print(f"   ✅ Generated {len(groups) + 1} Markdown files")

    def _write_index(self, index_content: Dict[str, str], navigation: List[Dict[str, Any]], groups: Dict[str, Dict[str, Any]]):
        lines = [
            "---",
            "id: index",
            "slug: /",
            f"title: {index_content['title']}",
            "sidebar_label: Overview",
            "---",
            "",
            f"# {index_content['title']}",
            "",
        ]

        if index_content['brief']:
            lines.extend([index_content['brief'], ""])

        if index_content['detailed']:
            lines.extend([index_content['detailed'], ""])

        lines.extend(["## Components", ""])
        for nav in navigation:
            if nav.get('group_ref') and nav['group_ref'] in groups:
                group = groups[nav['group_ref']]
                group_ref = nav['group_ref']
                lines.extend([
                    f"### [{group['title']}](./{group_ref})",
                    "",
                    group['brief'] if group['brief'] else '',
                    "",
                ])

        (self.output_dir / "index.md").write_text('\n'.join(lines), encoding='utf-8')
        print("   ✅ index.md")

    def _write_group(self, name: str, data: Dict[str, Any]):
        lines = [
            "---",
            f"id: {name}",
            f"title: {data['title']}",
            f"sidebar_label: {data['title']}",
            "---",
            "",
            f"# {data['title']}",
            "",
        ]

        if data['brief']:
            lines.extend([data['brief'], ""])

        if data['detailed']:
            lines.extend([data['detailed'], ""])

        if data['innergroups']:
            lines.extend(["## Sub-Modules", ""])
            for ig in data['innergroups']:
                ig_refid = ig['refid']
                ig_name = ig['name']

                group_id = ig_refid.replace('group__', '').replace('__', '_')
                display_name = ig_name.replace('wb_idf_i2c_', '').replace('_', ' ').title()

                lines.append(f"- [{display_name}](./{group_id})")
            lines.append("")

        if data['typedefs']:
            lines.extend(["## Type Definitions", ""])
            for typedef in data['typedefs']:
                lines.extend([
                    f"### `{typedef['name']}`",
                    "",
                    "```c",
                    typedef['definition'],
                    "```",
                    "",
                ])
                if typedef['brief']:
                    lines.extend([typedef['brief'], ""])

        if data['enums']:
            lines.extend(["## Enumerations", ""])
            for enum in data['enums']:
                lines.extend([f"### `{enum['name']}`", ""])
                if enum['brief']:
                    lines.extend([enum['brief'], ""])

                if enum['values']:
                    lines.extend(["| Enumerator | Value | Description |"])
                    lines.append("|------------|-------|-------------|")
                    for value in enum['values']:
                        val_str = value['initializer'] or ''
                        brief = value['brief'].replace('\n', ' ')[:50] if value['brief'] else ''
                        lines.append(f"| `{value['name']}` | {val_str} | {brief} |")
                    lines.append("")

        if data['defines']:
            lines.extend(["## Macros", ""])
            for define in data['defines']:
                value_str = f" {define['value']}" if define['value'] else ""
                lines.extend([f"### `{define['name']}{value_str}`", ""])
                if define['brief']:
                    lines.extend([define['brief'], ""])

        if data['functions']:
            lines.extend(["## Functions", ""])
            for func in data['functions']:
                lines.extend([
                    f"### {func['name']}",
                    "",
                ])

                if func['brief']:
                    lines.extend([func['brief'], ""])

                lines.extend([
                    "```c",
                    func['signature'],
                    "```",
                    "",
                ])

                if func['params']:
                    lines.extend(["**Parameters:**", ""])
                    for param in func['params']:
                        param_line = f"- **{param['name']}** (`{param['type']}`)"
                        if param['description']:
                            param_line += f": {param['description']}"
                        lines.append(param_line)
                    lines.append("")

                if func['return']:
                    lines.extend(["**Returns:**", "", func['return'], ""])

                if func['detailed'] and func['detailed'] != func['brief']:
                    lines.extend([func['detailed'], ""])

                lines.extend(["---", ""])

        output_file = self.output_dir / f"{name}.md"
        output_file.write_text('\n'.join(lines), encoding='utf-8')
        print(f"   ✅ {name}.md")

    def _write_sidebars(self, navigation: List[Dict[str, Any]], groups: Dict[str, Dict[str, Any]]):
        sidebar_items: List[Dict[str, Any]] = [
            {
                'type': 'doc',
                'id': 'index',
                'label': 'Overview',
            }
        ]

        for nav in navigation:
            if nav.get('type') == 'mainpage':
                continue

            if nav.get('group_ref') and nav['group_ref'] in groups:
                category: Dict[str, Any] = {
                    'type': 'category',
                    'label': nav.get('title', 'Unknown'),
                    'collapsible': True,
                    'collapsed': False,
                    'items': [nav['group_ref']],
                }

                for sub in nav.get('subtabs', []):
                    if sub.get('group_ref') and sub['group_ref'] in groups:
                        category['items'].append(sub['group_ref'])

                sidebar_items.append(category)

        sidebar_config = {
            'apiSidebar': sidebar_items,
        }

        config_file = self.output_dir / 'sidebars.json'
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(sidebar_config, f, indent=2, ensure_ascii=False)

        print("   ✅ sidebars.json")


def main() -> int:
    parser = argparse.ArgumentParser(description='Convert Doxygen to Docusaurus Markdown')
    parser.add_argument('--xml-dir', required=True, help='Doxygen XML directory')
    parser.add_argument('--layout', help='DoxygenLayout.xml file (optional)')
    parser.add_argument('--output', required=True, help='Output directory')
    parser.add_argument('--format', default='docusaurus', help='Output format (docusaurus)')

    args = parser.parse_args()

    xml_dir = Path(args.xml_dir)
    output_dir = Path(args.output)

    if not xml_dir.exists():
        print(f"❌ Error: {xml_dir} not found. Run 'doxygen Doxyfile' first!")
        return 1

    print("\n🚀 Converting Doxygen to Docusaurus Markdown\n")
    print("   ✅ Mermaid diagram support enabled")
    print("   ✅ @verbatim blocks with Mermaid auto-detection")
    print("   ✅ @mermaid tags and graph keyword detection")
    print("   ✅ Preserves spaces in Mermaid labels\n")

    navigation: List[Dict[str, Any]] = []
    if args.layout:
        layout_file = Path(args.layout)
        if layout_file.exists():
            layout_parser = DoxygenLayoutParser(layout_file)
            navigation = layout_parser.parse_navigation()
            print(f"✅ Parsed navigation from {layout_file.name}\n")

    xml_parser = DoxygenXMLParser(xml_dir)
    xml_parser.parse()

    generator = DocusaurusMarkdownGenerator(output_dir)
    generator.generate(navigation, xml_parser.groups, xml_parser.index_content)

    print(f"\n✅ Done! Markdown files generated in {output_dir}/")
    print("\n💡 Mermaid support:")
    print("   • Use @verbatim...@endverbatim for Mermaid diagrams (recommended)")
    print("   • Or use @mermaid...@endmermaid")
    print("   • Or use @code blocks with Mermaid syntax (auto-detected)")
    print("   • Spaces in labels are preserved")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())