from PIL import Image, UnidentifiedImageError
import os
import sys
from tkinter import Tk, filedialog

# A4 size at 150 DPI (in pixels)
A4_SIZE = (1240, 1754)
IMAGE_EXTS = ('.png', '.jpg', '.jpeg', '.bmp', '.webp', '.tiff')

def pick_folder():
    root = Tk()
    root.withdraw()
    return filedialog.askdirectory(title="Select folder containing images")

def resize_and_center(img, size):
    img = img.convert("RGB")
    img.thumbnail(size, Image.Resampling.LANCZOS)
    background = Image.new("RGB", size, (255, 255, 255))
    offset = (
        (size[0] - img.width) // 2,
        (size[1] - img.height) // 2
    )
    background.paste(img, offset)
    return background

def collect_images(folder_path, deep=False):
    image_files = []
    if deep:
        for root, _, files in os.walk(folder_path):
            for file in files:
                if file.lower().endswith(IMAGE_EXTS):
                    image_files.append(os.path.join(root, file))
    else:
        for file in os.listdir(folder_path):
            if file.lower().endswith(IMAGE_EXTS):
                image_files.append(os.path.join(folder_path, file))
    return sorted(image_files)

def main():
    # 🔹 Check for `-d` (deep) flag
    deep_mode = '-d' in sys.argv or '--deep' in sys.argv

    # 🔹 Ask for filename first
    output_name = input("Enter output PDF filename (without .pdf) or press ENTER to use folder name: ").strip()

    # 🔹 Folder selection
    folder_path = input("Enter folder path with images or press ENTER to browse: ").strip()
    if not folder_path:
        folder_path = pick_folder()

    if not folder_path or not os.path.isdir(folder_path):
        print("❌ Folder not found. Exiting.")
        return

    print(f"📂 Reading images from: {folder_path}")
    if deep_mode:
        print("🔁 Recursive mode enabled: including subfolders")

    # 🔹 Collect valid image files
    image_files = collect_images(folder_path, deep=deep_mode)

    if not image_files:
        print("⚠️ No supported image files found.")
        return

    # 🔹 Process images
    img_list = []
    for img_path in image_files:
        try:
            img = Image.open(img_path)
            img = resize_and_center(img, A4_SIZE)
            img_list.append(img)
        except UnidentifiedImageError:
            print(f"⚠️ Skipping unreadable file: {img_path}")

    if not img_list:
        print("❌ No valid images to convert. Exiting.")
        return

    # 🔹 Use folder name if filename was not given
    if not output_name:
        output_name = os.path.basename(folder_path)

    output_pdf_path = os.path.join(folder_path, f"{output_name}.pdf")
    first_img = img_list.pop(0)

    # 🔹 Save final PDF
    first_img.save(output_pdf_path, save_all=True, append_images=img_list)
    print(f"\n📄 PDF created successfully: {output_pdf_path}")

if __name__ == "__main__":
    main()
