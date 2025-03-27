# PDF to Image Converter 🖼️

A simple Python script that converts PDF pages to PNG images using `pdf2image`.

## 🚀 Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Make sure Poppler is installed and `pdftoppm` is in your system PATH.  
- Windows users: [Install instructions here](https://github.com/oschwartz10612/poppler-windows/releases/)

3. Place your PDF in the root folder and rename it to `sample.pdf`.

## 🔧 Usage

Run the script:
```bash
python convert_pdf.py
```
Output images will be saved as `page_1.png`, `page_2.png`, etc.

## 📁 Optional

To change the file name or DPI, edit `convert_pdf.py` or fork the project.
