import sys
import argparse
from tools import pdf_to_images, images_to_pdf

def main():
    # Create an argument parser
    parser = argparse.ArgumentParser(description="🛠️ Kuda Tools - PDF & Image Utilities")
    
    # Add subcommands or options (for different functionalities)
    parser.add_argument('command', choices=['pdf2images', 'images2pdf'], help='The command to run')

    # Parse arguments
    args = parser.parse_args()
    
    # Show help if no command is provided
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)

    # Execute the corresponding command
    if args.command == 'pdf2images':
        pdf_to_images.main()
    elif args.command == 'images2pdf':
        images_to_pdf.main()

if __name__ == "__main__":
    main()
