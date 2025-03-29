from pathlib import Path
from typing import List
from pypdf import PdfReader

def guess_output_name(pdf_paths: List[str]) -> str:
    """
    Generate a smart PDF output name:
    - Try using first file's metadata title (if it's useful)
    - Fallback: use 'firstfilename_to_lastfilename.pdf'
    """
    def is_generic_title(title: str) -> bool:
        generic_keywords = ["scan", "document", "file", "untitled"]
        return any(keyword in title.lower() for keyword in generic_keywords)

    try:
        reader = PdfReader(pdf_paths[0])
        title = reader.metadata.title
        if title and not is_generic_title(title):
            return f"{title.strip().replace(' ', '_')}.pdf"
    except Exception:
        pass  # skip metadata if unreadable

    first = Path(pdf_paths[0]).stem
    last = Path(pdf_paths[-1]).stem
    return f"{first}_to_{last}.pdf"
