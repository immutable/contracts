Contributing to Immutable zkEVM Contracts
We greatly appreciate all community feedback and contributions to this repository. This guide will walk you through the different ways you can contribute, including opening Github issues, pull requests, requesting features, and providing general feedback. For any security disclosures, please email [TODO-security@immutable.com]

Opening an issue
Github issues are a great way to discuss and coordinate new features, changes, bugs, etc, You can create an issue here.

You should create an issue to open discussions when:

Before starting development on a significant pull request - Use Github issues as a way to collaboratively propose, design, and discuss any development work you plan to do.
Proposing new features or ideas - If you just have an idea or feature you'd like to see, drop the details into a Github issue for us to keep track of. Be specific with any requests, and include descriptions of what you would like to be added and what problems it would solve.
Reporting a bug or security vulnerability - As above, opening an issue helps us keep track of and prioritize any bugs or vulnerabilities. Make sure to include all the relevant information, e.g. code snippets, error messages, stack traces, environment, reproduction steps, etc, to help us effectively diagnose and address the issue.
There is usually no need to create an issue when:

An issue or open PR for the topic already exists - Please continue or reopen the existing thread to keep all the discussion in one place.
The PR is relatively small and obvious (e.g. small fixes, typos, etc) - If the changes do not require a discussion, simply filling out the PR description template will suffice.
Requesting development help - If you run into any issues and require help setting up or using our contracts, feel free to reach out on Discord [TODO: what channel?] channel where we or the rest of the dev community will be happy to answer questions.
Providing comments or general feedback - We generally use Github issues for actionable feedback or tasks (e.g. feature requests or bugs), but we welcome all forms of feedback. We would love to see you share your thoughts and comments in our [TODO: what channel?] Discord channel and engage with the rest of the community.
Opening a Pull Request
If you'd like to contribute to the code and open a pull request (PR), here are some general guidelines to follow:

Most PRs should have an accompanying Github issue (see above on opening issues). When submitting your PR for review, please link the corresponding issue in the PR description.
Alongside every PR there should be a brief summary of what changes have been made and why, as per the PR template we provide. Be sure to fill this out to help share context with the reviewers and others.
Please follow existing code styles to keep formatting in this repository consistent.

Contributor workflow
To start contributing to this repository, have a look at this guide to contributing to open source projects.

You should fork the repository and make your changes in your local repository under a new branch, before opening a pull request for your branch back upstream to the original repository. This is a helpful guide that walks through all of these steps in detail.

Fork the repository (Fork button in the top right of the repository Github UI).
Clone your fork to your local machine.
git clone https://github.com/<your-github-username>/<repository-name>.git
Add the original repository as the upstream remote.
cd <repository-name>
git remote add upstream https://github.com/immutable/<repository-name>.git
Make sure your fork is up to date with the original repository (if necessary).
git pull upstream main
Create a new branch and make your changes.
git checkout -b <your-branch-name>
Be sure to run the tests and set up the relevant linters to ensure all Github checks pass.
npm test
Add and commit your changes, including a comprehensive commit message summarising your changes, then push changes to your fork.
git add *
git commit -m "fix typos"
git push origin <your-branch-name>
Open a pull request into the original repository through the Github in your web browser. Remember to fill out the PR template to the best of your ability to share any context with reviewers.

We will review the pull requests and request any necessary changes. If all the checks (linting, compilation, tests) pass and everything looks good, your code will be merged into the original repository. Congratulations, and thank you for your contribution!