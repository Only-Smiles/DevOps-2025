# Week 3 - 14.02.2025

## Implement an API for the simulator in your ITU-MiniTwit

We started by creating issues for the different endpoints.

We considered using GitHub Pages as an alternative to Digitalocean for hosting, but GitHub pages is only for static material and we also had group members that had used Digitalocean before.

We split up in pairs, with one working on deployment and one on implementing the endpoints. This ended up being harder than expected because we had issues just getting the test script to run properly. Specifically, the check for the request coming from the simulator always fails.

## Vagrant with local virtual machine

We started by creating a Vagrant file that sets up a local virtual machine, installs the necessary dependencies required to run our program, and executes it. We based our Vagrant file on the code provided in the exercises with only minor modifications.
Since everyone in our group except one person uses macOS with an ARM64 architecture, we couldn't use VirtualBox. Instead, some of us used UTM, while others opted for VMware.

To use UTM, we used this [installation guide](https://naveenrajm7.github.io/vagrant_utm/). 
To use VMware, we used this [installation guide](https://developer.hashicorp.com/vagrant/docs/providers/vmware/installation).

After successfully configuring a Vagrant file that could spin up an Ubuntu virtual machine and run our web server locally, we decided to refactor it into a hosted virtual machine using DigitalOcean.

## Vagrant with Digital Ocean
Choosing DigitalOcean was an easy decision for us since the GitHub Student Pack provides $200 in credits. From the course material, we knew that our web server would need to handle a high volume of traffic, and DigitalOcean allows us to easily scale up our web server to accommodate more requests.

We also explored the DigitalOcean API and web portal and found their documentation and UI very intuitive and easy to follow.

To set up our Vagrant file, we used a mix of DigitalOcean's official documentation and LLM-generated guidance. Since most of the heavy lifting had already been done when creating the local Vagrant file, we quickly managed to get a working VM running through the API.

## Vagrant with a Restricted (Floating) IP
Note: DigitalOcean has renamed from "Floating IP" to "Restricted IP," so I will refer to it as a Restricted IP, even though the project work instructions on GitHub still call it a Floating IP.

One issue with our previous approach is that we receive a new public IP address every time we deploy a new version of MiniTwit.
Another issue is that deploying a new version requires us to destroy the currently running VM and create a new one, leading to downtime where users can't access MiniTwit.

To solve this, we first created a Restricted IP in the DigitalOcean dashboard and assigned it to our running VM. Now, when we deploy a new version, we simply create a new VM and use the DigitalOcean dashboard to reassign the Restricted IP to the new instance.

To avoid doing this manually, we automated the process in our Vagrant file using the DigitalOcean API. Now, when we run vagrant up, it does the following:

Creates a new droplet with a unique name: `webserver-#{Time.now.strftime('%Y%m%d%H%M')}`.
Checks if a Restricted IP already exists.
If not, it creates a new one via the API.
If it does exist, we reuse the existing one.
It reassigns the restriced IP to the new VM and deletes the old one VM.
This eliminates downtime and ensures that the IP address remains the same across deployments.

## Implement an API for the simulator in you ITU Minitwit

We split our repository into frontend and API, which means there is a bit of code duplication. The reason for this is that the simulator wants status codes and json responses but our frontend returns http. We took that opportunity to also restructure the files, so that each endpoint is in its own file and can be implemented independently.

Laurids implemented the register and fllws endpoints and that is where we ended for the week, the rest of the endpoints will be implemented next week.

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
