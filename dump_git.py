import subprocess
with open('git_info.utf8.txt', 'w', encoding='utf-8') as f:
    f.write("STATUS\n" + subprocess.getoutput('git status') + "\n")
    f.write("BRANCHES\n" + subprocess.getoutput('git branch -v') + "\n")
    f.write("LOG\n" + subprocess.getoutput('git log --oneline -n 15') + "\n")
    f.write("STASH\n" + subprocess.getoutput('git stash list') + "\n")
    f.write("REFLOG\n" + subprocess.getoutput('git reflog -n 15') + "\n")
