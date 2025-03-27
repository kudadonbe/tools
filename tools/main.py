import sys
from tools import pdf_to_images, images_to_pdf

def main():
    if len(sys.argv) < 2:
        print("🛠️ Kuda Tools - PDF & Image Utilities")
        print("Usage:")
        print("  kuda pdf2images   - Convert PDF pages to images")
        print("  kuda images2pdf   - Merge images into a single PDF")
        sys.exit(1)

    command = sys.argv[1]

    if command == "pdf2images":
        pdf_to_images.main()
    elif command == "images2pdf":
        images_to_pdf.main()
    else:
        print(f"❌ Unknown command: {command}")
        print("Try: pdf2images or images2pdf")