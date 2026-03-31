import os
import re

def extract_paragraphs(input_path, output_path):
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Read input HTML file
    with open(input_path, 'r', encoding='utf-8') as file:
        html_content = file.read()
    
    # Use regex to extract paragraphs with class 'article__paragraph'|'article__sub-title'
    # and remove the class attribute
    matches = re.findall(r'<(p|h2)[^>]*class="[^"]*(?:article__paragraph|article__sub-title)[^"]*"[^>]*>(.*?)</\1>', html_content, re.DOTALL)
    
    # Create new HTML file with extracted paragraphs
    with open(output_path, 'w', encoding='utf-8') as outfile:
        for tag, content in matches:
            outfile.write(f'<{tag}>{content}</{tag}>\n')

def process_html_files(input_folder, output_folder):
    # Create output folder if it doesn't exist
    os.makedirs(output_folder, exist_ok=True)
    
    # Process each HTML file in the input folder
    for filename in os.listdir(input_folder):
        if filename.endswith('.html'):
            input_path = os.path.join(input_folder, filename)
            output_path = os.path.join(output_folder, filename)
            
            extract_paragraphs(input_path, output_path)
            print(f'Processed: {filename}')

# Example usage
input_folder = './input'
output_folder = './output'
process_html_files(input_folder, output_folder)