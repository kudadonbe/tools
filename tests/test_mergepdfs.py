import os
import shutil
from unittest.mock import patch
from click.testing import CliRunner
from pypdf import PdfWriter
from tools import mergepdfs

def test_merge_pdfs():
    # Create a dummy directory and two dummy PDF files
    dir_path = "dummy_pdfs"
    os.makedirs(dir_path, exist_ok=True)

    pdf_path1 = os.path.join(dir_path, "dummy1.pdf")
    writer1 = PdfWriter()
    writer1.add_blank_page(width=100, height=100)
    writer1.write(pdf_path1)

    pdf_path2 = os.path.join(dir_path, "dummy2.pdf")
    writer2 = PdfWriter()
    writer2.add_blank_page(width=100, height=100)
    writer2.write(pdf_path2)

    output_filename = "merged.pdf"
    output_pdf_path = os.path.join(dir_path, output_filename)

    # Use click's CliRunner to test the command
    runner = CliRunner()
    with patch('tools.mergepdfs.pick_folder', return_value=dir_path):
        result = runner.invoke(mergepdfs.merge_pdfs_command, [output_filename])

    assert result.exit_code == 0
    assert os.path.exists(output_pdf_path)

    # Clean up the dummy directory and output PDF
    shutil.rmtree(dir_path)
