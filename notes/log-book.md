# Week 3 - 14.02.2025

## Vagrant and Digital Ocean setup

Mac users were not able to install the VirtualBox program, as the architecture of VirtualBox is amd64 and our Macbooks have arm64. Some members in the group installed another Virtual Box, such as UTM, which supports arm64 architecture. If UTM is installed instead, an additional plugin to vagrant is needed, follow the [installation guide](https://naveenrajm7.github.io/vagrant_utm/).

However, we quickly found out, that we didn't need to set this up for the project, as we are depending on DigitalOcean cloud service. We followed the installation instructions for setting up Digital Ocean provided in the [README EXERCISE](https://github.com/itu-devops/lecture_notes/blob/master/sessions/session_03/README_EXERCISE.md) file from class.

After this we sat down and configure the Vagrantfile to spin up a VM on Digital Ocean. We set up all the required depenedencies to run the project. The virtual machine can be started by running `vagrant up` from the root in the project folder.

> NB! Right now the virtual machine is expecting you to have setup your Digital Ocean account, with ssh_keynam and token. You need to export these variables in your .zrch file. Your .zrch file should look something like this (replace the values with your personal values)

```
export SSH_KEY_NAME="{YOUR_DIGITAL_OCEAN_KEYNAME}"
export DIGITAL_OCEAN_TOKEN="{YOUR_DICITAL_OCEAN_TOKEN}"
```

# Week 2 - 07.02.2025

## Refactor ITU-MiniTwit to another language and technology of your choice.

### Brainstorming sesh

We started a brainstorming session where we listed up different tech-stacks that we could use. The following stacks were put on the board:

- Julia
- Rust
- Express
- Ruby
- Nim
- Elixir
- Go

Everyone got to research the programming languages for 10 minutes before we assigned stars to the languages.

We used a method from Software Architecture course where we all got 5 stars that we could distribute to the languages as we'd like. It was important to us, that the language chosen was stable and there was extensive documentation for it. 
We used [this for reference](https://survey.stackoverflow.co/2024/technology#most-popular-technologies-language-prof).

After placings stars we eliminated languages bottom-up, leaving us with only two to choose from:

- Ruby with Sinatra
    - Pros: Lightweight. Simplicity and productivity. Helge recommended it. No-one has explored it before, and we'd like to learn.
    - Cons: 
- Typescript/Javascript with Nest.js and Express.js
    - Pros:
    - Cons: Everyone has tried it before and we'd like to learn something new

We discussed pro's and cons for the two languages and voted. The results were:
- 5 in favor of Ruby
- 1 in favor of Express

Given this, we decided to go with Ruby for backend and use Sinatra for the framework.

### Refactoring from Python to Ruby

We decided to refactor the code together by bringing the code up to the screen and then all of us sitting and refactoring the code together. However we did not manage to do much progress, and decided to split up and work further on the refactoring individually or in pairs. We use discord for communication, so we decided that we will keep eachother up to date by communicating what we've done.

#### Known issues related

The Mac users had issues with ensuring that the correct Ruby version was used. We discovered that an older Ruby version already being installed on their laptops, and that the path was looking as this version instead of the new version installed by homebrew. In order to solve the issues, we updated the path on our laptops to point to the correct path in the homebrew folder.

### Branch naming convention

We discussed that we should keep some sort of branch naming convention. We used [this article](https://medium.com/@abhay.pixolo/naming-conventions-for-git-branches-a-cheatsheet-8549feca2534) for naming conventions. We didn't end up choosing any specific syntax, but we agree that we should have some kind of structure to link our branches to github issues.


# Week 1 - 31.01.2025

## 1. Adding Version Control
Added version control with Git and setup branch protection for main.

## 2. Try to develop a high-level understanding of ITU-MiniTwit.
Done

## 3. Migrate ITU-MiniTwit to run on a modern computer running Linux
We added Poetry to our project to manage packages in our project and added all dependencies [dependencies](../pyproject.toml)
We recompiled flag_tool with gcc.

To convert [minitwitt](../minitwit.py), we used 2to3 which removed a uncesesarry import and added parenthesis to a print statement.

We use shellcheck to lint check control.sh and fixed the warnings. We also used dos2unix to fix formatting issues from Windows
