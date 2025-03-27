from pdf2image import convert_from_path
from tkinter import Tk, filedialog
import questionary
import os
import sys

# Supported formats and defaults
SUPPORTED_FORMATS = {
    "PNG": "png (default, lossless, sharp)",
    "JPEG": "jpg (compressed, small size)",
    "BMP": "bmp (large, raw image)",
    "TIFF": "tiff (high quality, can be multi-page)",
    "WEBP": "webp (modern format, small size)"
}

DEFAULT_DPI = 200
DEFAULT_FORMAT = "PNG"
DPI_OPTIONS = [72, 150, 200, 300, 600]

def pick_pdf_file():
    root = Tk()
    root.withdraw()
    return filedialog.askopenfilename(
        title="Select a PDF file",
        filetypes=[("PDF Files", "*.pdf")]
    )

def get_file_extension(format_key):
    return "jpg" if format_key == "JPEG" else format_key.lower()

def main():
    # Determine mode
    interactive_mode = len(sys.argv) > 1

    if not interactive_mode:
        # Use defaults
        dpi = DEFAULT_DPI
        format_key = DEFAULT_FORMAT
        print(f"Using default settings: {dpi} DPI, {format_key} format")
    else:
        # Interactive selection
        dpi_choice = questionary.select(
            "📐 Choose DPI (resolution):",
            choices=[f"{dpi} DPI" for dpi in DPI_OPTIONS],
            default=f"{DEFAULT_DPI} DPI"
        ).ask()
        dpi = int(dpi_choice.split()[0])

        format_choice = questionary.select(
            "🖼️ Choose output image format:",
            choices=[f"{key} - {desc}" for key, desc in SUPPORTED_FORMATS.items()],
            default=f"{DEFAULT_FORMAT} - {SUPPORTED_FORMATS[DEFAULT_FORMAT]}"
        ).ask()
        format_key = format_choice.split(" - ")[0]

    # PDF file path
    pdf_path = input("\n📄 Enter PDF file path or press ENTER to browse: ").strip()
    if not pdf_path:
        pdf_path = pick_pdf_file()

    if not pdf_path or not os.path.exists(pdf_path):
        print("❌ PDF file not found. Exiting.")
        return

    print(f"\n🚀 Converting: {pdf_path}")
    print(f"🔧 DPI: {dpi}, Format: {format_key}")

    # Output folder = same folder as PDF, named by PDF file
    src_folder = os.path.dirname(pdf_path)
    base_name = os.path.splitext(os.path.basename(pdf_path))[0]
    output_folder = os.path.join(src_folder, base_name)
    os.makedirs(output_folder, exist_ok=True)

    # Convert and save
    ext = get_file_extension(format_key)
    images = convert_from_path(pdf_path, dpi=dpi)

    for i, img in enumerate(images):
        output_file = os.path.join(output_folder, f"{i + 1}.{ext}")
        img.save(output_file, format_key)
        print(f"✅ Saved: {output_file}")

    print(f"\n🎉 Done! All pages saved in: {output_folder}")

if __name__ == "__main__":
    main()
