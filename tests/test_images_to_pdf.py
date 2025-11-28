import os
import shutil
from unittest.mock import patch
from PIL import Image
from tools import images_to_pdf

def test_images_to_pdf():
    # Create a dummy directory and image file
    dir_path = "dummy_images"
    os.makedirs(dir_path, exist_ok=True)
    image_path = os.path.join(dir_path, "dummy.png")
    img = Image.new('RGB', (100, 100), color = 'red')
    img.save(image_path)

    output_filename = "output"
    output_pdf_path = os.path.join(dir_path, f"{output_filename}.pdf")

    # Mock the input function to provide the output filename and the path to the dummy image directory
    with patch('builtins.input', side_effect=[output_filename, dir_path]):
        # Run the images_to_pdf function
        images_to_pdf.main()

    # Check if the output PDF is created
    assert os.path.exists(output_pdf_path)

    # Clean up the dummy directory and output PDF
    shutil.rmtree(dir_path)