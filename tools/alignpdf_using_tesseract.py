# tools/alignpdf.py

import os
from pathlib import Path
from tkinter import Tk, filedialog
import click
import subprocess


def pick_folder() -> str:
    root = Tk()
    root.withdraw()
    return filedialog.askdirectory(title="Select folder with PDF files")


def get_pdf_files(folder: str) -> list[Path]:
    return sorted(
        [Path(folder) / f for f in os.listdir(folder) if f.lower().endswith(".pdf")]
    )


def run_ocrmypdf(input_path: Path, output_path: Path):
    try:
        result = subprocess.run([
            "ocrmypdf",
            "--rotate-pages",
            "--deskew",
            "--force-ocr",
            "--output-type", "pdf",
            str(input_path),
            str(output_path)
        ], capture_output=True, text=True)

        if result.returncode == 0:
            click.echo(f"✅ Saved: {output_path.name}\n")
        else:
            click.echo(f"⚠️ Warning: Failed to align {input_path.name}\n{result.stderr}\n")

    except Exception as e:
        click.echo(f"❌ Error processing {input_path.name}: {e}\n")


@click.command(name="alignpdf")
def align_pdf_command():
    """
    Align (deskew and auto-rotate) all scanned PDFs in a folder using ocrmypdf.
    Output files are saved as <original>_aligned.pdf in the same folder.
    """
    click.echo("📂 Select a folder containing scanned PDFs...")
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
        output_path = pdf_path.with_stem(pdf_path.stem + "_aligned")
        run_ocrmypdf(pdf_path, output_path)


if __name__ == "__main__":
    align_pdf_command()
