import os
import re
import tempfile
import shutil
import zipfile
import traceback
from typing import List
from fastapi import APIRouter, UploadFile, File
from fastapi.responses import StreamingResponse
from PyPDF2 import PdfMerger, PdfReader, PdfWriter

from reportlab.platypus import Paragraph, Spacer, Table, TableStyle
from reportlab.lib import colors

from app.services.pdf_service import PDFService
from app.core.config import settings

router = APIRouter()

@router.post("/pdf/merge")
async def merge_pdfs(files: List[UploadFile] = File(...)):
    merger = PdfMerger()
    temp_dir = tempfile.mkdtemp()
    try:
        paths = []
        for file in files:
            file_path = os.path.join(temp_dir, file.filename)
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            merger.append(file_path)
        
        output_path = os.path.join(temp_dir, "merged.pdf")
        merger.write(output_path)
        merger.close()
        
        return StreamingResponse(
            open(output_path, "rb"),
            media_type="application/pdf",
            headers={"Content-Disposition": "attachment; filename=merged.pdf"}
        )
    except Exception as e:
        return {"error": str(e)}

@router.post("/pdf/split")
async def split_pdf(file: UploadFile = File(...)):
    reader = PdfReader(file.file)
    temp_dir = tempfile.mkdtemp()
    try:
        zip_path = os.path.join(temp_dir, "split_pages.zip")
        with zipfile.ZipFile(zip_path, 'w') as zipf:
            for i in range(len(reader.pages)):
                writer = PdfWriter()
                writer.add_page(reader.pages[i])
                page_path = os.path.join(temp_dir, f"page_{i+1}.pdf")
                with open(page_path, "wb") as f:
                    writer.write(f)
                zipf.write(page_path, f"page_{i+1}.pdf")
        
        return StreamingResponse(
            open(zip_path, "rb"),
            media_type="application/zip",
            headers={"Content-Disposition": "attachment; filename=split_pages.zip"}
        )
    except Exception as e:
        print(f"Split PDF Error: {traceback.format_exc()}")
        return {"error": str(e)}

@router.post("/pdf/to-word")
async def pdf_to_word(file: UploadFile = File(...)):
    """PDF to Word with Engine-level Exact Match."""
    temp_dir = tempfile.mkdtemp(dir=settings.BASE_CONVERSION_DIR)
    try:
        pdf_path = os.path.join(temp_dir, file.filename)
        with open(pdf_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # 1. Try LibreOffice Engine (Highest Quality)
        output_path = PDFService.convert_with_libreoffice(pdf_path, "docx")
        
        if not output_path:
            # 2. Fallback to Deep Match internal logic
            print("[INFO] Engine failed. Using internal pdf2docx fallback.")
            docx_path = os.path.join(temp_dir, "output.docx")
            from pdf2docx import Converter
            cv = Converter(pdf_path)
            cv.convert(docx_path, start=0, end=None) 
            cv.close()
            output_path = docx_path
        
        return StreamingResponse(
            open(output_path, "rb"),
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            headers={"Content-Disposition": f"attachment; filename={os.path.basename(output_path)}"}
        )
    except Exception as e:
        print(f"PDF to Word Error: {traceback.format_exc()}")
        return {"error": f"Failed to convert PDF to Word: {str(e)}"}

@router.post("/pdf/word-to-pdf")
async def word_to_pdf(file: UploadFile = File(...)):
    """Word to PDF with Engine-level Exact Match."""
    temp_dir = tempfile.mkdtemp(dir=settings.BASE_CONVERSION_DIR)
    try:
        docx_path = os.path.join(temp_dir, file.filename)
        with open(docx_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # 1. Try LibreOffice Engine (100% Exact Matching)
        output_path = PDFService.convert_with_libreoffice(docx_path, "pdf")
        
        if not output_path:
            # 2. Fallback to Deep Match internal logic
            print("[INFO] Engine failed. Using internal ReportLab fallback.")
            pdf_path = os.path.join(temp_dir, "output.pdf")
            PDFService.convert_docx_to_pdf_internal(docx_path, pdf_path)
            output_path = pdf_path
        
        return StreamingResponse(
            open(output_path, "rb"),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={os.path.basename(output_path)}"}
        )
    except Exception as e:
        print(f"Word to PDF Error: {traceback.format_exc()}")
        return {"error": f"Conversion failed: {str(e)}"}

@router.post("/pdf/compress")
async def compress_pdf(file: UploadFile = File(...)):
    temp_dir = tempfile.mkdtemp()
    try:
        input_path = os.path.join(temp_dir, "input.pdf")
        output_path = os.path.join(temp_dir, "compressed.pdf")
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        reader = PdfReader(input_path)
        writer = PdfWriter()
        
        for page in reader.pages:
            page.compress_content_streams() # Basic compression
            writer.add_page(page)
            
        with open(output_path, "wb") as f:
            writer.write(f)
            
        return StreamingResponse(
            open(output_path, "rb"),
            media_type="application/pdf",
            headers={"Content-Disposition": "attachment; filename=compressed.pdf"}
        )
    except Exception as e:
        return {"error": str(e)}

@router.post("/pdf/to-excel")
async def pdf_to_excel(file: UploadFile = File(...)):
    """Improved PDF to Excel using structured extraction."""
    temp_dir = tempfile.mkdtemp()
    try:
        input_path = os.path.join(temp_dir, "input.pdf")
        output_path = os.path.join(temp_dir, "output.xlsx")
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        import pandas as pd
        
        reader = PdfReader(input_path)
        all_data = []
        
        for page in reader.pages:
            text = page.extract_text()
            if not text: continue
            
            lines = text.split('\n')
            for line in lines:
                if '\t' in line:
                    parts = line.split('\t')
                elif '    ' in line:
                    parts = re.split(r'\s{3,}', line)
                else:
                    parts = [line.strip()]
                
                if parts and any(p.strip() for p in parts):
                    all_data.append(parts)
        
        if not all_data:
            return {"error": "No text could be extracted from this PDF."}
            
        df = pd.DataFrame(all_data)
        df.to_excel(output_path, index=False, header=False)
        
        return StreamingResponse(
            open(output_path, "rb"),
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={"Content-Disposition": "attachment; filename=output.xlsx"}
        )
    except Exception as e:
        print(f"PDF to Excel Error: {traceback.format_exc()}")
        return {"error": str(e)}

@router.post("/pdf/excel-to-pdf")
async def excel_to_pdf(file: UploadFile = File(...)):
    """Professional Excel to PDF using Platypus Tables."""
    temp_dir = tempfile.mkdtemp()
    try:
        input_path = os.path.join(temp_dir, "input.xlsx")
        output_path = os.path.join(temp_dir, "output.pdf")
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        import pandas as pd
        df = pd.read_excel(input_path)
        df = df.fillna("") # Clean NaNs
        
        styles = PDFService.get_styles()
        elements = []
        
        elements.append(Paragraph(f"Spreadsheet Export: {file.filename}", styles['HeaderName']))
        elements.append(Spacer(1, 20))
        
        data = [df.columns.tolist()] + df.values.tolist()
        
        col_count = len(df.columns)
        col_widths = [500 / col_count for _ in range(col_count)]
        
        t = Table(data, colWidths=col_widths)
        t.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#2C3E50")),
            ('TEXTCOLOR', (0,0), (-1,0), colors.white),
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('FONTSIZE', (0,0), (-1,-1), 8 if col_count > 6 else 10),
            ('BOTTOMPADDING', (0,0), (-1,0), 12),
            ('BACKGROUND', (0,1), (-1,-1), colors.whitesmoke),
            ('GRID', (0,0), (-1,-1), 0.5, colors.grey),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ]))
        
        elements.append(t)
        
        return PDFService.create_platypus_pdf_response(elements, 'output.pdf')
        
    except Exception as e:
        print(f"Excel to PDF Error: {traceback.format_exc()}")
        return {"error": str(e)}

@router.post("/pdf/ppt-to-pdf")
async def ppt_to_pdf(file: UploadFile = File(...)):
    return {"error": "PowerPoint to PDF requires LibreOffice for reliable conversion. Basic text extraction coming soon!"}
