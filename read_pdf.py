import pdfplumber
with pdfplumber.open('d:/Personal/Project/Mobile/dev/daraz_ui/Flutter Hiring task 2026.pdf') as pdf:
    for i, page in enumerate(pdf.pages):
        print(f'--- Page {i+1} ---')
        text = page.extract_text()
        if text:
            print(text)
