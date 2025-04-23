# tools/alignpdf.py

import os
from pathlib import Path
from tkinter import Tk, filedialog
import click
from pdf2image import convert_from_path
from PIL import Image
import cv2
import numpy as np


def pick_folder() -> str:
    root = Tk()
    root.withdraw()
    return filedialog.askdirectory(title="Select folder with PDF files")


def get_pdf_files(folder: str) -> list[Path]:
    return sorted(
        [Path(folder) / f for f in os.listdir(folder) if f.lower().endswith(".pdf")]
    )


def detect_skew_angle(image: np.ndarray) -> float:
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    gray = cv2.bitwise_not(gray)
    thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)[1]
    coords = np.column_stack(np.where(thresh > 0))
    angle = cv2.minAreaRect(coords)[-1]
    if angle < -45:
        angle = -(90 + angle)
    else:
        angle = -angle
    return angle


def align_image(img: Image.Image) -> Image.Image:
    # Convert to OpenCV format
    cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    angle = detect_skew_angle(cv_img)

    # ✅ Avoid false rotation: only apply deskew if skew is small (<10°)
    if abs(angle) > 10:
        angle = 0

    (h, w) = cv_img.shape[:2]
    center = (w // 2, h // 2)
    matrix = cv2.getRotationMatrix2D(center, angle, 1.0)

    # Compute new bounding box size
    cos = np.abs(matrix[0, 0])
    sin = np.abs(matrix[0, 1])
    new_w = int((h * sin) + (w * cos))
    new_h = int((h * cos) + (w * sin))

    # Adjust the rotation matrix to account for translation
    matrix[0, 2] += (new_w / 2) - center[0]
    matrix[1, 2] += (new_h / 2) - center[1]

    # Rotate without clipping
    rotated = cv2.warpAffine(cv_img, matrix, (new_w, new_h), flags=cv2.INTER_LINEAR, borderValue=(255, 255, 255))

    # Resize and center on A4 canvas (at 300 DPI)
    A4_SIZE = (2480, 3508)
    pil_rotated = Image.fromarray(cv2.cvtColor(rotated, cv2.COLOR_BGR2RGB))
    pil_rotated.thumbnail(A4_SIZE, Image.Resampling.LANCZOS)
    background = Image.new("RGB", A4_SIZE, (255, 255, 255))
    offset = ((A4_SIZE[0] - pil_rotated.width) // 2, (A4_SIZE[1] - pil_rotated.height) // 2)
    background.paste(pil_rotated, offset)
    return background


@click.command(name="alignpdf")
def align_pdf_command():
    """
    Align (deskew) all portrait-scanned PDFs in a folder (no OCR used).
    Output files are saved as <original>_aligned.pdf in the same folder.
    """
    click.echo("📂 Select a folder containing portrait-scanned PDFs...")
    folder_path = pick_folder()

    if not folder_path:
        click.echo("❌ No folder selected. Exiting.")
        return

    pdf_files = get_pdf_files(folder_path)
    if not pdf_files:
        click.echo("⚠️ No PDF files found in the selected folder.")
        return

    for pdf_path in pdf_files:
        click.echo(f"🌀 Aligning: {pdf_path.name}")
        try:
            images = convert_from_path(str(pdf_path), dpi=300)
            aligned_images = [align_image(img) for img in images]

            out_path = pdf_path.with_stem(pdf_path.stem + "_aligned")
            aligned_images[0].save(out_path, save_all=True, append_images=aligned_images[1:])
            click.echo(f"✅ Saved: {out_path.name}\n")

        except Exception as e:
            click.echo(f"❌ Failed to align {pdf_path.name}: {e}\n")


if __name__ == "__main__":
    align_pdf_command()
