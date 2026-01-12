import os

def fix_encoding(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".md"):
                path = os.path.join(root, file)
                try:
                    # Try reading with utf-8-sig (handles BOM) or euc-kr/cp949
                    content = None
                    for enc in ['utf-8-sig', 'euc-kr', 'cp949', 'utf-16']:
                        try:
                            with open(path, 'r', encoding=enc) as f:
                                content = f.read()
                            print(f"Read {file} with {enc}")
                            break
                        except:
                            continue
                    
                    if content:
                        with open(path, 'w', encoding='utf-8', newline='\n') as f:
                            f.write(content)
                        print(f"Fixed {file}")
                except Exception as e:
                    print(f"Failed to fix {file}: {e}")

fix_encoding('tasks/prds')
