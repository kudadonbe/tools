# tools/mergepdfs.py

import click
import os
from pathlib import Path
from pypdf import PdfWriter
from tools.utils import guess_output_name
from tkinter import Tk, filedialog


def pick_folder() -> str:
    """Open folder picker dialog and return selected path."""
    root = Tk()
    root.withdraw()
    return filedialog.askdirectory(title="Select folder with PDF files")


def get_pdf_files(folder: str) -> list[Path]:
    """Return a list of .pdf files in the given folder, sorted by name."""
    return sorted(
        [Path(folder) / f for f in os.listdir(folder) if f.lower().endswith(".pdf")]
    )


@click.command(name="mergepdfs")
@click.argument("output_name", required=False)
@click.option(
    "--sort",
    type=click.Choice(["name", "date"]),
    default="name",
    help="Sort PDF files by name or date.",
)
def merge_pdfs_command(output_name, sort):
    """
    Merge all PDF files in a selected folder into one.

    \b
    Usage:
      kdm mergepdfs MyReport        # output = MyReport.pdf
      kdm mergepdfs                 # output = auto-guessed name
    """

    click.echo("📂 Select a folder containing PDF files...\n")
    folder_path = pick_folder()

    if not folder_path:
        click.echo("❌ No folder selected. Exiting.")
        return

    pdf_files = get_pdf_files(folder_path)
    if sort == "date":
        pdf_files.sort(key=lambda p: p.stat().st_mtime)

    if len(pdf_files) < 2:
        click.echo("⚠️ Need at least two PDF files in the folder.")
        return

    # Determine output name
    if output_name:
        final_name = output_name.strip()
    else:
        final_name = guess_output_name([str(p) for p in pdf_files])

    click.echo(f"\n📝 Output file will be: {final_name}")

    # Ensure .pdf extension
    if not final_name.lower().endswith(".pdf"):
        final_name += ".pdf"

    output_path = Path(folder_path) / final_name

    if output_path.exists():
        if not click.confirm(f"❗ '{final_name}' already exists. Overwrite?", default=False):
            click.echo("❌ Merge cancelled.")
            return

    # Merge PDFs
    writer = PdfWriter()
    try:
        for file in pdf_files:
            click.echo(f"➕ Adding: {file.name}")
            with open(file, "rb") as f:
                writer.append(f)
        with open(output_path, "wb") as out:
            writer.write(out)
        click.echo(f"\n✅ Merged PDF saved as: {output_path.resolve()}")
    except Exception as e:
        click.echo(f"❌ Error during merge: {e}")


# Allow calling from CLI via `mergepdfs.main()`
def main():
    merge_pdfs_command(prog_name="kdm merge")


if __name__ == "__main__":
    main()
