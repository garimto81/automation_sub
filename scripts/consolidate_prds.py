import os

def merge_files(output_path, input_paths):
    content = ""
    for p in input_paths:
        if os.path.exists(p):
            with open(p, 'r', encoding='utf-8') as f:
                content += f.read() + "\n\n---\n\n"
        else:
            print(f"Warning: {p} not found")
    
    with open(output_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content.strip())
    print(f"Merged into {output_path}")

# PRD-0007
merge_files('tasks/prds/0007-prd-4schema-database-design.md', [
    'tasks/prds/0007/01-overview.md',
    'tasks/prds/0007/04-data-flow.md'
])
merge_files('tasks/prds/0007-spec-database-implementation.md', [
    'tasks/prds/0007/02-schema-architecture.md',
    'tasks/prds/0007/03-cross-schema-mapping.md',
    'tasks/prds/0007/05-implementation-guide.md'
])

# PRD-0006
merge_files('tasks/prds/0006-prd-aep-data-elements.md', [
    'tasks/prds/0006/01-overview.md',
    'tasks/prds/0006/02-data-sources.md'
])
merge_files('tasks/prds/0006-spec-aep-details.md', [
    'tasks/prds/0006/03-caption-fields.md',
    'tasks/prds/0006/04-db-mapping.md',
    'tasks/prds/0006/05-input-guide.md'
])

# PRD-0001 (Split single large file into 2)
p0001 = 'tasks/prds/0001-prd-wsop-broadcast-graphics.md'
if os.path.exists(p0001):
    with open(p0001, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    # Split around line 750 (where Appendix C / Design Guidelines usually start)
    split_idx = 750
    if len(lines) > split_idx:
        with open('tasks/prds/0001-prd-wsop-broadcast-graphics.md', 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(lines[:split_idx])
        with open('tasks/prds/0001-spec-design-appendix.md', 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(lines[split_idx:])
        print(f"Split PRD-0001 into 2 files")

# PRD-0003 (Split single large file into 2)
p0003 = 'tasks/prds/0003-prd-caption-workflow.md'
if os.path.exists(p0003):
    with open(p0003, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    split_idx = 600
    if len(lines) > split_idx:
        with open('tasks/prds/0003-prd-caption-workflow.md', 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(lines[:split_idx])
        with open('tasks/prds/0003-spec-caption-database.md', 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(lines[split_idx:])
        print(f"Split PRD-0003 into 2 files")
