# Python Tools (`kdm` CLI)

This directory contains the Python source code for the `kdm` command-line tool, a multipurpose PDF and image utility.

## Commands

The `kdm` tool provides the following commands:

*   `kdm pdf2images`: Converts a PDF file to a series of images.
*   `kdm images2pdf`: Merges a series of images into a single PDF file.
*   `kdm merge`: Merges multiple PDF files into a single PDF file.

## Development

To set up the development environment, you will need to have Python 3.8+ and `pip` installed.

1.  **Install Dependencies:**

    From the root of the project, run the following command to install the required dependencies:

    ```bash
    pip install -e ".[dev]"
    ```

2.  **Run Tests:**

    To run the test suite, use `pytest`:

    ```bash
    pytest
    ```

3.  **Run the Linter:**

    To check the code for style and errors, use `ruff`:

    ```bash
    ruff check .
    ```
