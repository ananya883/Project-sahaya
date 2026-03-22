import subprocess
with open('git_investigate.utf8.txt', 'w', encoding='utf-8') as f:
    f.write("SHOW 6621b87 STAT:\n" + subprocess.getoutput('git show --stat 6621b87') + "\n\n")
    f.write("DIFF HEAD 6621b87:\n" + subprocess.getoutput('git diff --stat HEAD 6621b87') + "\n\n")
