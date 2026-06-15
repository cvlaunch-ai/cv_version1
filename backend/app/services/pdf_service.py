import io
import os
import re
import time
import shutil
import tempfile
import zipfile
import subprocess
from datetime import datetime
from typing import List
from fastapi.responses import StreamingResponse
from PyPDF2 import PdfMerger, PdfReader, PdfWriter

from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.utils import simpleSplit
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_JUSTIFY, TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib import colors

from app.core.config import settings

class PDFService:
    @staticmethod
    def get_soffice_path() -> str:
        for path in settings.LIBREOFFICE_PATHS:
            if path == "soffice" or os.path.exists(path):
                return path
        return None

    @classmethod
    def convert_with_libreoffice(cls, input_path: str, output_ext: str) -> str:
        """Uses LibreOffice Headless to convert documents with 100% exact layout."""
        soffice = cls.get_soffice_path()
        if not soffice:
            print("[WARN] LibreOffice not found. Falling back to internal engine.")
            return None
            
        try:
            outdir = os.path.dirname(input_path)
            cmd = [soffice, "--headless", "--convert-to", output_ext, "--outdir", outdir, input_path]
            print(f"Executing Engine: {' '.join(cmd)}")
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if result.returncode == 0:
                base_name = os.path.splitext(os.path.basename(input_path))[0]
                output_path = os.path.join(outdir, f"{base_name}.{output_ext}")
                
                if os.path.exists(output_path):
                    # Save a copy to D Drive Downloads as requested
                    copy_path = os.path.join(settings.DOWNLOADS_DIR, f"{base_name}_{int(time.time())}.{output_ext}")
                    shutil.copy2(output_path, copy_path)
                    print(f"✅ Exact Match Saved to: {copy_path}")
                    return output_path
            
            print(f"LibreOffice Error: {result.stderr}")
            return None
        except Exception as e:
            print(f"Engine Error: {e}")
            return None

    @staticmethod
    def create_text_file_response(content: str, filename: str) -> StreamingResponse:
        """Create a StreamingResponse for a plain text file download."""
        file_like = io.BytesIO(content.encode("utf-8"))
        return StreamingResponse(
            file_like,
            media_type="text/plain",
            headers={"Content-Disposition": f"attachment; filename=\"{filename}\""},
        )

    @staticmethod
    def create_platypus_pdf_response(elements, filename: str) -> StreamingResponse:
        """Builds a PDF from a list of Flowables (Paragraphs, Tables, etc.)"""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer, 
            pagesize=letter,
            rightMargin=50, leftMargin=50, 
            topMargin=50, bottomMargin=50
        )
        doc.build(elements)
        buffer.seek(0)
        return StreamingResponse(
            buffer, 
            media_type='application/pdf', 
            headers={
                'Content-Disposition': f'attachment; filename="{filename}"'
            }
        )

    @staticmethod
    def get_styles():
        styles = getSampleStyleSheet()
        # Add styles safely, checking if they exist to prevent crashes
        styles_to_add = [
            ParagraphStyle(name='Justify', parent=styles['Normal'], alignment=TA_JUSTIFY, spaceAfter=6),
            ParagraphStyle(name='Center', parent=styles['Normal'], alignment=TA_CENTER, spaceAfter=6),
            ParagraphStyle(name='HeaderName', parent=styles['Normal'], alignment=TA_CENTER, fontSize=24, fontName='Helvetica-Bold', spaceAfter=12),
            ParagraphStyle(name='HeaderContact', parent=styles['Normal'], alignment=TA_CENTER, fontSize=10, fontName='Helvetica', spaceAfter=20, textColor=colors.darkgrey),
            ParagraphStyle(name='SectionHeader', parent=styles['Normal'], fontSize=14, fontName='Helvetica-Bold', spaceAfter=6, spaceBefore=12, borderPadding=2, borderColor=colors.black, borderWidth=0, borderRadius=0)
        ]
        for style in styles_to_add:
            try:
                styles.add(style)
            except ValueError:
                pass
        return styles

    @classmethod
    def create_classic_pdf_response(cls, final_data: dict) -> StreamingResponse:
        """
        1:1 Sync Template: Matches the user's minimalist original (Image 1).
        Centered Header, Left-Aligned Body, No Lines, Helvetica Font.
        """
        styles = cls.get_styles()
        
        name_style = ParagraphStyle('NameStyle', parent=styles['Normal'], fontSize=16, alignment=TA_CENTER, fontName='Helvetica-Bold', spaceAfter=2)
        contact_style = ParagraphStyle('ContactStyle', parent=styles['Normal'], fontSize=10, alignment=TA_CENTER, fontName='Helvetica', spaceAfter=15)
        section_style = ParagraphStyle('SecStyle', parent=styles['Normal'], fontSize=12, fontName='Helvetica-Bold', spaceBefore=15, spaceAfter=0, textTransform='uppercase')
        line_style = ParagraphStyle('LineStyle', parent=styles['Normal'], fontSize=10, fontName='Helvetica-Bold', textColor=colors.black, leading=6, spaceAfter=10)
        body_style = ParagraphStyle('BodyStyle', parent=styles['Normal'], fontSize=10, leading=13, alignment=TA_LEFT)
        bullet_style = ParagraphStyle('BulletStyle', parent=body_style, leftIndent=15, firstLineIndent=0, spaceAfter=4)
        
        story = []
        story.append(Paragraph(final_data["full_name"], name_style))
        
        contact = " • ".join(filter(None, [final_data.get('phone'), final_data.get('email'), final_data.get('location')]))
        if contact:
            story.append(Paragraph(contact, contact_style))
        
        def add_section(title, content):
            if not content: return
            story.append(Paragraph(title, section_style))
            story.append(Paragraph("__________________________________________________________________________________", line_style))
            
            lines = content.split('\n')
            for line in lines:
                line = line.strip()
                if not line: continue
                
                formatted = line.replace("**", "<b>").replace("**", "</b>")
                
                if line.startswith('•') or line.startswith('-') or line.startswith('*'):
                    clean_line = re.sub(r'^[\s•\-\*]+', '', line)
                    story.append(Paragraph(f"• {clean_line}", bullet_style))
                else:
                    story.append(Paragraph(formatted, body_style))
            story.append(Spacer(1, 5))

        add_section("PROFESSIONAL SUMMARY", final_data.get("summary"))
        add_section("ACADEMIC PROFILE", final_data.get("education"))
        add_section("WORK EXPERIENCE", final_data.get("responsibilities"))
        add_section("PROJECTS", final_data.get("projects"))
        add_section("TECHNOLOGIES & TOOLS", final_data.get("skills"))
        if final_data.get("certifications"):
            add_section("CERTIFICATIONS", final_data.get("certifications"))
        
        return cls.create_platypus_pdf_response(story, 'resume.pdf')

    @classmethod
    def create_modern_resume_response(cls, data: dict, filename: str) -> StreamingResponse:
        """
        Template 45 Style: Modern Blue Header with Clean Layout
        Optimized for correct formatting from build_resume_data.
        """
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=letter,
            rightMargin=40, leftMargin=40,
            topMargin=40, bottomMargin=40
        )
        
        styles = getSampleStyleSheet()
        story = []
        
        header_color = colors.HexColor("#2C3E50")
        text_white = colors.white
        
        name = data.get("full_name", "Your Name").upper()
        
        header_style = ParagraphStyle('ModernHeader', parent=styles['Normal'], fontSize=24, textColor=text_white, alignment=TA_CENTER, fontName='Helvetica-Bold')
        contact_style = ParagraphStyle('ModernContact', parent=styles['Normal'], fontSize=10, textColor=text_white, alignment=TA_CENTER, fontName='Helvetica')
        
        contact_text = f"{data.get('phone','')} | {data.get('email','')} | {data.get('location','')}"
        
        p_name = Paragraph(name, header_style)
        p_contact = Paragraph(contact_text, contact_style)
        
        header_data = [[p_name], [p_contact]]
        t_header = Table(header_data, colWidths=['100%'])
        t_header.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), header_color),
            ('TOPPADDING', (0,0), (-1,-1), 20),
            ('BOTTOMPADDING', (0,0), (-1,-1), 20),
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ]))
        
        story.append(t_header)
        story.append(Spacer(1, 20))
        
        section_head_style = ParagraphStyle('ModernSection', parent=styles['Normal'], fontSize=14, textColor=header_color, fontName='Helvetica-Bold', spaceBefore=15, spaceAfter=5)
        body_style = ParagraphStyle('ModernBody', parent=styles['Normal'], fontSize=11, leading=14)
        
        def clean_text_for_pdf(text):
            if not text: return ""
            t = re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', text)
            t = re.sub(r'\*(.*?)\*', r'<i>\1</i>', t)
            return t

        def add_modern_section(title, content):
            if not content: return
            story.append(Paragraph(title.upper(), section_head_style))
            story.append(Table([['']], colWidths=['100%'], rowHeights=[1], style=TableStyle([('LINEBELOW', (0,0), (-1,-1), 1, colors.lightgrey)])))
            story.append(Spacer(1, 8))
            
            lines = content.split('\n')
            for line in lines:
                line = line.strip()
                if not line: continue
                
                formatted_line = clean_text_for_pdf(line)
                
                if line.startswith('•') or line.startswith('-'):
                    bullet_style = ParagraphStyle('Bullet', parent=body_style, leftIndent=15, firstLineIndent=0)
                    story.append(Paragraph(formatted_line, bullet_style))
                else:
                    story.append(Paragraph(formatted_line, body_style))
            
            story.append(Spacer(1, 10))

        add_modern_section("Professional Summary", data.get("summary", ""))
        add_modern_section("Education", data.get("education", ""))
        add_modern_section("Roles & Responsibilities", data.get("responsibilities", ""))
        add_modern_section("Projects", data.get("projects", ""))
        add_modern_section("Technologies & Tools", data.get("skills", ""))
        add_modern_section("Certifications", data.get("certifications", ""))
        
        doc.build(story)
        buffer.seek(0)
        return StreamingResponse(buffer, media_type='application/pdf', headers={
            'Content-Disposition': f'attachment; filename="{filename}"'
        })

    @classmethod
    def convert_docx_to_pdf_internal(cls, docx_path: str, pdf_path: str):
        """Deep Match Conversion: Extracts exact font sizes, colors, and layout."""
        from docx import Document as DocxDocument
        from docx.shared import Pt, RGBColor
        from docx.enum.text import WD_ALIGN_PARAGRAPH
        from docx.oxml.table import CT_Tbl
        from docx.oxml.text.paragraph import CT_P
        from docx.table import Table as DocxTable
        from docx.text.paragraph import Paragraph as DocxPara

        doc = DocxDocument(docx_path)
        styles = cls.get_styles()
        elements = []
        
        def rgb_to_hex(rgb_color):
            if not rgb_color: return colors.black
            try:
                return colors.HexColor(f"#{rgb_color}")
            except:
                return colors.black

        default_font_size = 10

        for block in doc.element.body:
            if isinstance(block, CT_P):
                para = DocxPara(block, doc)
                if not para.text.strip():
                    elements.append(Spacer(1, 6))
                    continue
                
                align = TA_LEFT
                if para.alignment == WD_ALIGN_PARAGRAPH.CENTER: align = TA_CENTER
                elif para.alignment == WD_ALIGN_PARAGRAPH.RIGHT: align = TA_RIGHT
                elif para.alignment == WD_ALIGN_PARAGRAPH.JUSTIFY: align = TA_JUSTIFY
                
                left_indent = para.paragraph_format.left_indent.pt if para.paragraph_format.left_indent else 0
                space_before = para.paragraph_format.space_before.pt if para.paragraph_format.space_before else 0
                space_after = para.paragraph_format.space_after.pt if para.paragraph_format.space_after else 4
                
                if space_before > 0: elements.append(Spacer(1, space_before))

                full_text = ""
                f_size = default_font_size
                for run in para.runs:
                    if not run.text: continue
                    t = run.text.replace("<", "&lt;").replace(">", "&gt;")
                    
                    f_size = run.font.size.pt if run.font.size else default_font_size
                    f_color = rgb_to_hex(run.font.color.rgb) if run.font.color and run.font.color.rgb else colors.black
                    
                    if run.bold: t = f"<b>{t}</b>"
                    if run.underline: t = f"<u>{t}</u>"
                    if run.italic: t = f"<i>{t}</i>"
                    
                    t = f'<font size="{f_size}" color="{f_color}">{t}</font>'
                    full_text += t
                
                if full_text:
                    custom_style = ParagraphStyle(
                        'Dynamic', 
                        parent=styles['Normal'], 
                        alignment=align, 
                        leftIndent=left_indent,
                        leading=max(12, f_size * 1.2)
                    )
                    elements.append(Paragraph(full_text, custom_style))
                    elements.append(Spacer(1, space_after))
                    
            elif isinstance(block, CT_Tbl):
                table = DocxTable(block, doc)
                table_data = []
                for row in table.rows:
                    row_data = []
                    for cell in row.cells:
                        cell_text = ""
                        for p in cell.paragraphs:
                            for run in p.runs:
                                t = run.text.replace("<", "&lt;").replace(">", "&gt;")
                                f_size = run.font.size.pt if run.font.size else 9
                                if run.bold: t = f"<b>{t}</b>"
                                cell_text += f'<font size="{f_size}">{t}</font>'
                        row_data.append(Paragraph(cell_text.strip(), styles['Normal']))
                    table_data.append(row_data)
                
                if table_data:
                    available_width = 500
                    col_widths = [available_width / len(table_data[0])] * len(table_data[0])
                    t = Table(table_data, colWidths=col_widths)
                    t.setStyle(TableStyle([
                        ('VALIGN', (0,0), (-1,-1), 'TOP'),
                        ('LEFTPADDING', (0,0), (-1,-1), 2),
                        ('RIGHTPADDING', (0,0), (-1,-1), 2),
                    ]))
                    elements.append(t)
                    elements.append(Spacer(1, 10))
            
        pdf_doc = SimpleDocTemplate(
            pdf_path, pagesize=letter,
            rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40
        )
        pdf_doc.build(elements)
