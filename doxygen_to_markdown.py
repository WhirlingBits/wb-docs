#!/usr/bin/env python3
"""
Doxygen XML → Docusaurus Markdown Converter
Creates clean .md files (no MDX, no JSX issues)
FLAT STRUCTURE (no api/ subdirectories)
FIX: Hybrid-Ansatz für Main Page (@section Support) + Listen-Deduplizierung
"""

import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List, Optional, Set
import argparse
import json
import re

class DoxygenLayoutParser:
    """Parst DoxygenLayout.xml für Navigation"""
    
    def __init__(self, layout_file: Path):
        self.layout_file = layout_file
    
    def parse_navigation(self) -> List[Dict]:
        """Extrahiert Navigation"""
        if not self.layout_file.exists():
            return []
        
        tree = ET.parse(self.layout_file)
        root = tree.getroot()
        
        navigation = []
        navindex = root.find('.//navindex')
        
        if navindex is None:
            return navigation
        
        for tab in navindex.findall('tab'):
            if tab.get('visible', 'yes') == 'yes':
                nav_item = self._parse_tab(tab)
                if nav_item:
                    navigation.append(nav_item)
        
        return navigation
    
    def _parse_tab(self, tab) -> Optional[Dict]:
        """Parse einzelnen Tab"""
        tab_type = tab.get('type', 'user')
        title = tab.get('title', '')
        url = tab.get('url', '')
        
        # Extrahiere Group Reference
        ref_match = re.search(r'@ref\s+(\w+)', url)
        group_ref = ref_match.group(1) if ref_match else None
        
        # Parse Sub-Tabs
        subtabs = []
        for subtab in tab.findall('tab'):
            sub_item = self._parse_tab(subtab)
            if sub_item:
                subtabs.append(sub_item)
        
        return {
            'type': tab_type,
            'title': title,
            'group_ref': group_ref,
            'subtabs': subtabs
        }

class DoxygenXMLParser:
    """Parst Doxygen XML Dateien"""
    
    def __init__(self, xml_dir: Path):
        self.xml_dir = xml_dir
        self.groups: Dict[str, Dict] = {}
        self.index_content: Optional[Dict] = None
        self._processed_para_ids: Set[int] = set()  # Track verarbeitete <para> Elemente
    
    def parse(self):
        """Parse alle XML Dateien"""
        print("📖 Parsing Doxygen XML...")
        
        # Main Page
        self._parse_index()
        
        # Groups
        group_files = list(self.xml_dir.glob("group__*.xml"))
        for xml_file in group_files:
            self._parse_group(xml_file)
        
        print(f"   ✅ Parsed {len(self.groups)} groups")
    
    def _parse_index(self):
        """Parse Main Page"""
        for filename in ['indexpage.xml', 'index.xml']:
            index_file = self.xml_dir / filename
            if index_file.exists():
                tree = ET.parse(index_file)
                compound = tree.find('.//compounddef[@kind="page"]')
                
                if compound is not None:
                    title = compound.findtext('title', 'API Documentation')
                    
                    # Reset tracking für neue Description
                    self._processed_para_ids.clear()
                    brief = self._get_description_all(compound.find('briefdescription'))
                    
                    self._processed_para_ids.clear()
                    detailed = self._get_description_all(compound.find('detaileddescription'))
                    
                    self.index_content = {
                        'title': title,
                        'brief': brief,
                        'detailed': detailed
                    }
                    return
    
    def _parse_group(self, xml_file: Path):
        """Parse Group XML"""
        try:
            tree = ET.parse(xml_file)
            compound = tree.find('.//compounddef[@kind="group"]')
            
            if compound is None:
                return
            
            name = compound.findtext('compoundname', '')
            title = compound.findtext('title', name)
            
            # Reset tracking
            self._processed_para_ids.clear()
            brief = self._get_description_direct(compound.find('briefdescription'))
            
            self._processed_para_ids.clear()
            detailed = self._get_description_direct(compound.find('detaileddescription'))
            
            # Innergroups
            innergroups = []
            for ig in compound.findall('.//innergroup'):
                innergroups.append({
                    'refid': ig.get('refid'),
                    'name': ig.text
                })
            
            # Members
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
                'defines': defines
            }
            
        except Exception as e:
            print(f"   ⚠️  Warning: Could not parse {xml_file.name}: {e}")
    
    def _get_description_all(self, elem) -> str:
        """
        Extracts description - ALLE verschachtelten <para> (für Main Page mit @section)
        Mit Deduplizierung via Element-ID-Tracking
        """
        if elem is None:
            return ""
        
        parts = []
        # Alle para Elemente finden (auch verschachtelte)
        for para in elem.findall('.//para'):
            para_id = id(para)
            
            # Skip wenn schon verarbeitet
            if para_id in self._processed_para_ids:
                continue
            
            self._processed_para_ids.add(para_id)
            
            text = self._parse_para(para)
            if text:
                parts.append(text)
        
        return '\n\n'.join(parts)
    
    def _get_description_direct(self, elem) -> str:
        """
        Extracts description - NUR direkte <para> Kinder (für Groups)
        """
        if elem is None:
            return ""
        
        parts = []
        # Nur DIREKTE para Kinder
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
        """
        Parse Paragraph mit Markdown-Formatierung
        Listen werden separat behandelt
        """
        result = []
        
        # Check ob dieses Para eine Liste enthält
        has_itemizedlist = para.find('.//itemizedlist') is not None
        
        if has_itemizedlist:
            # Paragraph enthält Liste -> NUR die Liste ausgeben
            # Text DAVOR und DANACH
            if para.text and para.text.strip():
                result.append(para.text.strip())
            
            for child in para:
                if child.tag == 'itemizedlist':
                    items = []
                    for listitem in child.findall('.//listitem'):
                        # Markiere listitem para als verarbeitet
                        listitem_para = listitem.find('.//para')
                        if listitem_para is not None:
                            self._processed_para_ids.add(id(listitem_para))
                        
                        item_text = self._extract_text_only(listitem)
                        if item_text:
                            items.append(f"- {item_text}")
                    
                    if items:
                        result.append('\n\n' + '\n'.join(items) + '\n')
                
                # Text nach dem Child
                if child.tail and child.tail.strip():
                    result.append(child.tail.strip())
            
            return '\n\n'.join(result).strip()
        
        # Normaler Paragraph ohne Liste
        if para.text and para.text.strip():
            result.append(para.text.strip())
        
        for child in para:
            if child.tag == 'ref':
                text = child.text or ''
                result.append(f"`{text}`")
            
            elif child.tag == 'computeroutput':
                code = ''.join(child.itertext())
                result.append(f"`{code}`")
            
            elif child.tag == 'programlisting':
                code_lines = []
                for codeline in child.findall('.//codeline'):
                    line = ''.join(codeline.itertext())
                    code_lines.append(line)
                code_block = '\n'.join(code_lines)
                result.append(f"\n\n```c\n{code_block}\n```\n")
            
            elif child.tag == 'simplesect':
                # Handle @section, @subsection etc.
                kind = child.get('kind', '')
                if kind in ['note', 'warning', 'see']:
                    sect_title = kind.capitalize()
                    sect_content = self._parse_simplesect(child)
                    if sect_content:
                        result.append(f"\n\n**{sect_title}:** {sect_content}\n")
            
            if child.tail and child.tail.strip():
                result.append(child.tail.strip())
        
        return ' '.join(filter(None, result)).strip()
    
    def _parse_simplesect(self, simplesect) -> str:
        """Parse simplesect (note, warning, etc.)"""
        parts = []
        for para in simplesect.findall('.//para'):
            para_id = id(para)
            if para_id not in self._processed_para_ids:
                self._processed_para_ids.add(para_id)
                text = self._parse_para(para)
                if text:
                    parts.append(text)
        return ' '.join(parts)
    
    def _extract_text_only(self, elem) -> str:
        """
        Extrahiert NUR den Text aus einem Element (keine Formatierung).
        Verwendet für Listen-Items.
        """
        text_parts = []
        
        # Finde das para Element im listitem
        para = elem.find('.//para')
        if para is None:
            return ""
        
        # Initial text
        if para.text and para.text.strip():
            text_parts.append(para.text.strip())
        
        # Verarbeite Children
        for child in para:
            # Child text
            if child.text and child.text.strip():
                text_parts.append(child.text.strip())
            
            # Tail text
            if child.tail and child.tail.strip():
                text_parts.append(child.tail.strip())
        
        return ' '.join(text_parts).strip()
    
    def _parse_function(self, elem) -> Optional[Dict]:
        """Parse Function"""
        try:
            name = elem.findtext('name', '')
            definition = elem.findtext('definition', '')
            argsstring = elem.findtext('argsstring', '')
            
            self._processed_para_ids.clear()
            brief = self._get_description_direct(elem.find('briefdescription'))
            
            self._processed_para_ids.clear()
            detailed = self._get_description_direct(elem.find('detaileddescription'))
            
            # Parameters
            params = []
            for param in elem.findall('.//param'):
                param_type_elem = param.find('type')
                param_type = ''.join(param_type_elem.itertext()) if param_type_elem is not None else ''
                param_name = param.findtext('declname', '')
                
                # Parameter Description
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
                    'description': param_desc
                })
            
            # Return Description
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
                'return': return_desc
            }
        except:
            return None
    
    def _parse_typedef(self, elem) -> Optional[Dict]:
        """Parse Typedef"""
        try:
            self._processed_para_ids.clear()
            return {
                'name': elem.findtext('name', ''),
                'definition': elem.findtext('definition', ''),
                'brief': self._get_description_direct(elem.find('briefdescription'))
            }
        except:
            return None
    
    def _parse_enum(self, elem) -> Optional[Dict]:
        """Parse Enum"""
        try:
            values = []
            for val in elem.findall('.//enumvalue'):
                self._processed_para_ids.clear()
                values.append({
                    'name': val.findtext('name', ''),
                    'initializer': val.findtext('initializer', ''),
                    'brief': self._get_description_direct(val.find('briefdescription'))
                })
            
            self._processed_para_ids.clear()
            return {
                'name': elem.findtext('name', ''),
                'brief': self._get_description_direct(elem.find('briefdescription')),
                'values': values
            }
        except:
            return None
    
    def _parse_define(self, elem) -> Optional[Dict]:
        """Parse Define"""
        try:
            self._processed_para_ids.clear()
            return {
                'name': elem.findtext('name', ''),
                'value': elem.findtext('initializer', ''),
                'brief': self._get_description_direct(elem.find('briefdescription'))
            }
        except:
            return None

class DocusaurusMarkdownGenerator:
    """Generiert sauberes Docusaurus Markdown - FLACHE STRUKTUR"""
    
    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
    
    def generate(self, navigation: List[Dict], groups: Dict, index_content: Optional[Dict]):
        """Generiere alle Markdown-Dateien - DIREKT im output_dir (FLACH)"""
        print("📝 Generating Docusaurus Markdown...")

        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Index
        if index_content:
            self._write_index(index_content, navigation, groups)
        
        # Groups (DIRECTLY in output_dir)
        for group_name, group_data in groups.items():
            self._write_group(group_name, group_data)

        # Sidebars Config
        self._write_sidebars(navigation, groups)
        
        print(f"   ✅ Generated {len(groups) + 1} Markdown files")
    
    def _write_index(self, index_content: Dict, navigation: List[Dict], groups: Dict):
        """Schreibe index.md - DIREKT im output_dir"""
        lines = [
            "---",
            "id: index",
            "slug: /",
            f"title: {index_content['title']}",
            "sidebar_label: Overview",
            "---",
            "",
            f"# {index_content['title']}",
            ""
        ]
        
        if index_content['brief']:
            lines.extend([index_content['brief'], ""])
        
        if index_content['detailed']:
            lines.extend([index_content['detailed'], ""])
        
        # Component Overview
        lines.extend(["## Components", ""])
        for nav in navigation:
            if nav.get('group_ref') and nav['group_ref'] in groups:
                group = groups[nav['group_ref']]
                group_ref = nav['group_ref']
                lines.extend([
                    f"### [{group['title']}](./{group_ref})",
                    "",
                    group['brief'] if group['brief'] else '',
                    ""
                ])
        
        (self.output_dir / "index.md").write_text('\n'.join(lines), encoding='utf-8')
        print(f"   ✅ index.md")
    
    def _write_group(self, name: str, data: Dict):
        """Schreibe Group Markdown - DIREKT im output_dir"""
        lines = [
            "---",
            f"id: {name}",
            f"title: {data['title']}",
            f"sidebar_label: {data['title']}",
            "---",
            "",
            f"# {data['title']}",
            ""
        ]
        
        if data['brief']:
            lines.extend([data['brief'], ""])
        
        if data['detailed']:
            lines.extend([data['detailed'], ""])
        
        # Sub-Modules
        if data['innergroups']:
            lines.extend(["## Sub-Modules", ""])
            for ig in data['innergroups']:
                ig_name = ig['name']
                lines.append(f"- [{ig_name}](./{ig_name})")
            lines.append("")
        
        # Typedefs
        if data['typedefs']:
            lines.extend(["## Type Definitions", ""])
            for typedef in data['typedefs']:
                lines.extend([
                    f"### `{typedef['name']}`",
                    "",
                    "```c",
                    typedef['definition'],
                    "```",
                    ""
                ])
                if typedef['brief']:
                    lines.extend([typedef['brief'], ""])
        
        # Enums
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
        
        # Defines
        if data['defines']:
            lines.extend(["## Macros", ""])
            for define in data['defines']:
                value_str = f" {define['value']}" if define['value'] else ""
                lines.extend([f"### `{define['name']}{value_str}`", ""])
                if define['brief']:
                    lines.extend([define['brief'], ""])
        
        # Functions
        if data['functions']:
            lines.extend(["## Functions", ""])
            
            for func in data['functions']:
                lines.extend([
                    f"### {func['name']}",
                    ""
                ])
                
                if func['brief']:
                    lines.extend([func['brief'], ""])
                
                lines.extend([
                    "```c",
                    func['signature'],
                    "```",
                    ""
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
    
    def _write_sidebars(self, navigation: List[Dict], groups: Dict):
        """Generiere sidebars.json - DIREKT im output_dir"""
        sidebar_items = [
            {
                'type': 'doc',
                'id': 'index',
                'label': 'Overview'
            }
        ]
        
        for nav in navigation:
            if nav.get('type') == 'mainpage':
                continue
            
            if nav.get('group_ref') and nav['group_ref'] in groups:
                category = {
                    'type': 'category',
                    'label': nav.get('title', 'Unknown'),
                    'collapsible': True,
                    'collapsed': False,
                    'items': [nav['group_ref']]
                }
                
                # Sub-Tabs
                for sub in nav.get('subtabs', []):
                    if sub.get('group_ref') and sub['group_ref'] in groups:
                        category['items'].append(sub['group_ref'])
                
                sidebar_items.append(category)
        
        sidebar_config = {
            'apiSidebar': sidebar_items
        }
        
        config_file = self.output_dir / 'sidebars.json'
        
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(sidebar_config, f, indent=2, ensure_ascii=False)
        
        print(f"   ✅ sidebars.json")

def main():
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
    
    print(f"\n🚀 Converting Doxygen to Docusaurus Markdown (FIX: Hybrid + Tracking)\n")
    
    # Parse Layout (optional)
    navigation = []
    if args.layout:
        layout_file = Path(args.layout)
        if layout_file.exists():
            layout_parser = DoxygenLayoutParser(layout_file)
            navigation = layout_parser.parse_navigation()
            print(f"✅ Parsed navigation from {layout_file.name}\n")
    
    # Parse XML
    xml_parser = DoxygenXMLParser(xml_dir)
    xml_parser.parse()
    
    # Generate Markdown (FLAT STRUCTURE)
    generator = DocusaurusMarkdownGenerator(output_dir)
    generator.generate(navigation, xml_parser.groups, xml_parser.index_content)
    
    print(f"\n✅ Done! Markdown files in {output_dir}/")
    print(f"   sidebars.json in {output_dir}/")
    print(f"   ✂️  Fixed: Hybrid approach (@section support + deduplication)")
    
    return 0

if __name__ == "__main__":
    exit(main())