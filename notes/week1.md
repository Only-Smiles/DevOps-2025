# Week 1

## 1. Adding Version Control
Added version control with Git and setup branch protection for main.

## 2. Try to develop a high-level understanding of ITU-MiniTwit.
Done

## 3. Migrate ITU-MiniTwit to run on a modern computer running Linux
We added Poetry to our project to manage packages in our project and added all dependencies [dependencies](../pyproject.toml)
We recompiled flag_tool with gcc.

To convert [minitwitt](../minitwit.py), we used 2to3 which removed a uncesesarry import and added parenthesis to a print statement.

We use shellcheck to lint check control.sh and fixed the warnings. We also used dos2unix to fix formatting issues from Windows
