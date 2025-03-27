from PIL import Image
import os
from tkinter import Tk, filedialog

def pick_folder():
    root = Tk()
    root.withdraw()
    folder = filedialog.askdirectory(title="Select folder containing images")
    return folder

def main():
    folder_path = input("Enter folder path with images or press ENTER to browse: ").strip()
    if not folder_path:
        folder_path = pick_folder()

    if not folder_path or not os.path.isdir(folder_path):
        print("❌ Folder not found. Exiting.")
        return

    print(f"📂 Reading images from: {folder_path}")

    # Collect all PNG images (you can add more formats)
    images = [f for f in os.listdir(folder_path) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    images.sort()  # Make sure they're in order: 1.png, 2.png...

    if not images:
        print("⚠️ No images found in this folder.")
        return

    # Open images using Pillow
    img_list = []
    for img_name in images:
        path = os.path.join(folder_path, img_name)
        img = Image.open(path).convert("RGB")
        img_list.append(img)

    # Use first image as the starting page
    first_img = img_list.pop(0)

    # Set output PDF path
    pdf_name = os.path.basename(folder_path) + ".pdf"
    output_pdf_path = os.path.join(os.path.dirname(folder_path), pdf_name)

    # Save PDF
    first_img.save(output_pdf_path, save_all=True, append_images=img_list)
    print(f"📄 PDF created: {output_pdf_path}")

if __name__ == "__main__":
    main()
