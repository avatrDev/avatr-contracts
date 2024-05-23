# Contributing to Avatr

First off, thank you for considering contributing to this project. It's people like you that make it such a great tool.

The following is a set of guidelines for contributing to this project. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](./CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [enquiries@spartalabs.org].

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report for this project. Following these guidelines helps maintainers and the community understand your report, reproduce the behavior, and find related reports.


#### How Do I Submit A (Good) Bug Report?

Bugs are tracked as [GitHub issues](https://github.com/avatrDev/avatr-contracts/issues). After you've determined that your bug is new, create an issue and provide the following information:

- **Use a clear and descriptive title** for the issue to identify the problem.
- **Describe the steps to reproduce the bug** as clearly as possible.
- **Explain which behavior you expected** to see instead and why.
- **Include screenshots and links** to code to help us understand the issue.

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion, including completely new features and minor improvements to an existing functionality. Before creating enhancement suggestions, please check the issues to see if it has already been suggested.

#### How Do I Submit A (Good) Enhancement Suggestion?

Enhancement suggestions are tracked as [GitHub issues](#). Provide the following information:

- **Use a clear and descriptive title** for the issue to identify the suggestion.
- **Provide a step-by-step description** of the suggested enhancement in as many details as possible.
- **Explain why this enhancement would be useful** to most users.
- **Include relevant examples** or screenshots.

### Pull Requests

#### How Do I Submit A (Good) Pull Request?

- Ensure any install or build dependencies are removed before the end of the layer when doing a build.
- Update the README.md with details of changes to the interface, including new environment variables, exposed ports, useful file locations, and container parameters.
- Ensure all tests pass.
- Follow the Solidity Style Guide outlined below.
- You may merge the Pull Request in once you have the sign-off of two other developers, or if you do not have permission to do that, you may request the second reviewer to merge it for you.

## Style Guides

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature").
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...").
- Limit the first line to 72 characters or less.
- Reference issues and pull requests liberally after the first line.

### Solidity Style Guide

All Solidity code should follow the official [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html). Key points include:

- **File Names**: Use CamelCase for new contract file names, e.g., `MyContract.sol`.
- **Indentation**: Use 4 spaces per indentation level.
- **Line Length**: Limit lines to 79 characters.
- **Naming Conventions**: Use mixedCase for functions and variables. Use CapitalizedWords for contract names.
- **State Variables**: Group related state variables together and separate them with a single line.
- **Order of Functions**: Follow the order - constructor, fallback function (if exists), external functions, public functions, internal functions, private functions, and then the rest.

### Documentation Style Guide

All documentation should adhere to the [Google Developer Documentation Style Guide](https://developers.google.com/style).

## Additional Notes

### Issue and Pull Request Labels

This section lists the labels we use to help us track and manage issues and pull requests.

- **bug**: Something isn't working
- **documentation**: Improvements or additions to documentation
- **duplicate**: This issue or pull request already exists
- **enhancement**: New feature or request
- **good first issue**: Good for newcomers
- **help wanted**: Extra attention is needed
- **invalid**: This doesn't seem right
- **question**: Further information is requested
