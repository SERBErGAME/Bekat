import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn
import os

HERE = os.path.dirname(os.path.abspath(__file__))
MD_PATH = os.path.join(HERE, "BEKAT_ARCHITECTURE.md")
OUT_DOCX = os.path.join(HERE, "Bekat_Texnik_Sxema_va_Arxitektura.docx")

doc = docx.Document()

# Page setup: A4, 2 cm margins
for section in doc.sections:
    section.page_width = Inches(8.27)
    section.page_height = Inches(11.69)
    section.top_margin = Inches(0.7)
    section.bottom_margin = Inches(0.7)
    section.left_margin = Inches(0.8)
    section.right_margin = Inches(0.8)

# Styling helper
def set_cell_background(cell, fill_hex):
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

# Title
p_title = doc.add_paragraph()
r_title = p_title.add_run("BEKAT — ТЕХНИЧЕСКАЯ СХЕМА И АРХИТЕКТУРА")
r_title.bold = True
r_title.font.size = Pt(20)
r_title.font.color.rgb = RGBColor(0x15, 0x17, 0x1C)
p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER

p_sub = doc.add_paragraph()
r_sub = p_sub.add_run("Понятное руководство по техническому устройству мобильного и веб-приложения умной маршрутизации и интерактивной карты общественного транспорта Намангана")
r_sub.font.size = Pt(11)
r_sub.font.italic = True
r_sub.font.color.rgb = RGBColor(0x5B, 0x62, 0x70)
p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER

# Metadata box
table_meta = doc.add_table(rows=1, cols=1)
table_meta.alignment = WD_TABLE_ALIGNMENT.CENTER
cell_meta = table_meta.rows[0].cells[0]
set_cell_background(cell_meta, "EEF1F6")
set_cell_margins(cell_meta, top=140, bottom=140, left=200, right=200)
p_m = cell_meta.paragraphs[0]
p_m.paragraph_format.space_after = Pt(2)
r_m = p_m.add_run("Языки: ")
r_m.bold = True
p_m.add_run("O'zbekcha (uz) • Русский (ru) • English (en)  |  ")
r_m2 = p_m.add_run("Платформы: ")
r_m2.bold = True
p_m.add_run("Android (APK v1.0.0), iOS, Web (Flutter & Dart)\n")
r_m3 = p_m.add_run("Авторы: ")
r_m3.bold = True
p_m.add_run("Кодиров Улугбек (Lead & Mobile Dev), Замалитдинов Салим (Backend & Alg. Dev) · НамГТУ, 37-АТТ, 4-курс")

doc.add_paragraph().paragraph_format.space_after = Pt(6)

# Read markdown lines and parse sections
with open(MD_PATH, "r", encoding="utf-8") as f:
    lines = f.readlines()

in_table = False
table_data = []

def flush_table():
    global table_data, in_table
    if not table_data:
        in_table = False
        return
    cols = len(table_data[0])
    tbl = doc.add_table(rows=len(table_data), cols=cols)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    for r_idx, row in enumerate(table_data):
        for c_idx, val in enumerate(row):
            if c_idx < len(tbl.rows[r_idx].cells):
                cell = tbl.rows[r_idx].cells[c_idx]
                set_cell_margins(cell, top=80, bottom=80, left=120, right=120)
                cell.paragraphs[0].paragraph_format.space_after = Pt(2)
                p = cell.paragraphs[0]
                text_clean = val.strip()
                if r_idx == 0:
                    set_cell_background(cell, "2D6BF0")
                    r = p.add_run(text_clean)
                    r.bold = True
                    r.font.size = Pt(9.5)
                    r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
                else:
                    if r_idx % 2 == 1:
                        set_cell_background(cell, "F8FAFC")
                    else:
                        set_cell_background(cell, "FFFFFF")
                    r = p.add_run(text_clean)
                    r.font.size = Pt(9)
                    r.font.color.rgb = RGBColor(0x15, 0x17, 0x1C)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)
    table_data = []
    in_table = False

skip_header = True
for line in lines:
    stripped = line.strip()
    if not stripped:
        if in_table:
            flush_table()
        continue
    
    if stripped.startswith("# BEKAT"):
        continue
    if stripped.startswith("### Понятное руководство"):
        continue
    if "Языки системы:" in stripped:
        continue
    if stripped.startswith("| О документе"):
        continue
    if stripped == "| :--- |":
        continue
    if "Этот документ объясняет техническое устройство" in stripped:
        continue

    # Table row
    if stripped.startswith("|") and stripped.endswith("|"):
        # Check if separator
        if ":---" in stripped or "---" in stripped:
            continue
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        table_data.append(cells)
        in_table = True
        continue
    elif in_table:
        flush_table()

    # Headings
    if stripped.startswith("## "):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(6)
        r = p.add_run(stripped[3:])
        r.bold = True
        r.font.size = Pt(13)
        r.font.color.rgb = RGBColor(0x2D, 0x6B, 0xF0)
        
        # Insert image for Section 3
        if "3. Общая техническая схема" in stripped:
            diag_p = os.path.join(HERE, "assets", "bekat_architecture_diagram.png")
            if os.path.exists(diag_p):
                p_img = doc.add_paragraph()
                p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p_img.paragraph_format.space_after = Pt(10)
                p_img.add_run().add_picture(diag_p, width=Inches(6.4))
                
        # Insert image for Section 4
        elif "4. Как работает алгоритм" in stripped:
            flow_p = os.path.join(HERE, "assets", "raptor_flow_diagram.png")
            if os.path.exists(flow_p):
                p_img = doc.add_paragraph()
                p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p_img.paragraph_format.space_after = Pt(10)
                p_img.add_run().add_picture(flow_p, width=Inches(6.4))
                
        # Insert scheme for Section 5
        elif "5. Интерактивная 3D-карта" in stripped:
            scheme_p = os.path.join(HERE, "assets", "scheme_ru.png")
            if os.path.exists(scheme_p):
                p_img = doc.add_paragraph()
                p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p_img.paragraph_format.space_after = Pt(10)
                p_img.add_run().add_picture(scheme_p, width=Inches(5.5))

    elif stripped.startswith("### "):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(3)
        r = p.add_run(stripped[4:])
        r.bold = True
        r.font.size = Pt(11)
        r.font.color.rgb = RGBColor(0x15, 0x17, 0x1C)
    elif stripped.startswith("```"):
        continue
    elif stripped.startswith("│") or stripped.startswith("┌") or stripped.startswith("└") or stripped.startswith("├") or stripped.startswith("▼") or stripped.startswith("──"):
        continue
    elif stripped.startswith("* ") or stripped.startswith("- "):
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.space_after = Pt(2)
        r = p.add_run(stripped[2:])
        r.font.size = Pt(9.5)
    elif stripped.startswith("1. ") or stripped.startswith("2. ") or stripped.startswith("3. ") or stripped.startswith("4. "):
        p = doc.add_paragraph(style='List Number')
        p.paragraph_format.space_after = Pt(2)
        r = p.add_run(stripped[3:])
        r.font.size = Pt(9.5)
    else:
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(4)
        r = p.add_run(stripped)
        r.font.size = Pt(10)
        r.font.color.rgb = RGBColor(0x15, 0x17, 0x1C)

if in_table:
    flush_table()

doc.save(OUT_DOCX)
print("Saved DOCX:", OUT_DOCX)
