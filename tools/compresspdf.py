# tools/compresspdf.py

import os
from pathlib import Path
from tkinter import Tk, filedialog
import click
import pikepdf


def pick_folder() -> str:
    root = Tk()
    root.withdraw()
    return filedialog.askdirectory(title="Select folder with PDF files to compress")


def get_pdf_files(folder: str) -> list[Path]:
    return sorted(
        [Path(folder) / f for f in os.listdir(folder) if f.lower().endswith(".pdf")]
    )


def compress_pdf(input_path: Path, output_path: Path, compression_level: str):
    try:
        with pikepdf.open(input_path) as pdf:
            # Set object stream mode for compression
            if compression_level == "low":
                pdf.save(output_path, 
                         compress_streams=True, 
                         object_stream_mode=pikepdf.ObjectStreamMode.generate)
            elif compression_level == "high":
                pdf.save(output_path, 
                         compress_streams=False, 
                         object_stream_mode=pikepdf.ObjectStreamMode.disable)
            else:  # medium (default)
                pdf.save(output_path, 
                         compress_streams=True, 
                         object_stream_mode=pikepdf.ObjectStreamMode.preserve)

        click.echo(f"✅ Compressed: {output_path.name}")
    except Exception as e:
        click.echo(f"❌ Failed to compress {input_path.name}: {e}")


@click.command(name="compresspdf")
@click.option('--level', type=click.Choice(['low', 'medium', 'high']), default='medium', help='Compression level (default: medium)')
def compress_pdf_command(level):
    """
    Compress all PDF files in a selected folder.
    Outputs <original>_compressed.pdf next to the original.
    """
    click.echo("📂 Select a folder containing PDFs to compress...")
    folder_path = pick_folder()

    if not folder_path:
        click.echo("❌ No folder selected. Exiting.")
        return

    pdf_files = get_pdf_files(folder_path)
    if not pdf_files:
        click.echo("⚠️ No PDF files found in the selected folder.")
        return

    for pdf_path in pdf_files:
        output_path = pdf_path.with_stem(pdf_path.stem + "_compressed")
        compress_pdf(pdf_path, output_path, compression_level=level)


if __name__ == "__main__":
    compress_pdf_command()