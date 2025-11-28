import os
import shutil
from unittest.mock import patch
from pypdf import PdfWriter
from tools import pdf_to_images

def test_pdf_to_images():
    # Create a dummy PDF file
    pdf_path = "dummy.pdf"
    writer = PdfWriter()
    writer.add_blank_page(width=100, height=100)
    writer.write(pdf_path)

    # Mock the input function to provide the path to the dummy PDF
    with patch('builtins.input', return_value=pdf_path):
        # Run the pdf_to_images function
        pdf_to_images.main()

    # Check if the output folder and images are created
    output_folder = os.path.splitext(pdf_path)[0]
    assert os.path.exists(output_folder)
    # Check for png by default
    output_file = os.path.join(output_folder, "1.png")
    assert os.path.exists(output_file)

    # Clean up the dummy PDF and output folder
    os.remove(pdf_path)
    shutil.rmtree(output_folder)