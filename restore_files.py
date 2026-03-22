import subprocess

# Get modified files in the working directory to avoid overwriting them
status_out = subprocess.getoutput("git status --porcelain")
uncommitted = [line[3:] for line in status_out.split('\n') if line]

# Get files from the lost commit
commit_out = subprocess.getoutput("git show --name-status 6621b87")
files_to_restore = []

for line in commit_out.split('\n'):
    parts = line.split('\t')
    if len(parts) >= 2:
        status, file_path = parts[0], parts[-1]
        
        # Skip node_modules and .idea
        if 'node_modules' in file_path or '.idea' in file_path or '.env' in file_path:
            continue
            
        # Skip if in uncommitted changes
        if file_path in uncommitted:
            print(f"Skipping {file_path} because you have uncommitted changes.")
            continue
            
        files_to_restore.append(file_path)

# Restore the files
for file_path in files_to_restore:
    cmd = f"git checkout 6621b87 -- \"{file_path}\""
    print(f"Restoring: {file_path}")
    subprocess.call(cmd, shell=True)
    
print("\nDone restoring early warning files!")
