# Code Quality Guidelines

This document outlines the tools and standards used to maintain code quality in this project. Please follow these guidelines to ensure the codebase remains clean, efficient, and secure.

## Quality Tools

### Clippy

[Clippy](https://doc.rust-lang.org/clippy/usage.html) is a Rust linter that provides a collection of lints to catch common mistakes and improve code quality.

- **How to Run Clippy Locally:**
  To run Clippy, execute the following command:
  ```bash
    cargo clippy -- -D warnings

This will cause the build to fail if there are any warnings or errors.

Clippy on CI: Clippy is run automatically on CI as part of the build process. Ensure that no warnings or errors are present before pushing your changes.

### Rustfmt

[Rustfmt](https://doc.rust-lang.org/clippy/development/adding_lints.html#running-rustfmt) automatically formats Rust code to conform to style guidelines.

- **How to Run Rustfmt Locally:**
  To check if your code is formatted properly, run:
  ```bash
    cargo fmt -- --check

This will not modify any files but will indicate if formatting is required.

Rustfmt on CI: Rustfmt is run as part of the CI pipeline, and the build will fail if there are formatting issues.

### Cargo Audit

[Cargo Audit](https://docs.rs/cargo-audit/latest/cargo_audit/) checks for known vulnerabilities in the dependencies of your project.

- **How to Run Cargo Audit Locally:**
  To check for security vulnerabilities, run:
  ```bash
    cargo audit

If any vulnerabilities are found, please resolve them before submitting your code.

### Running Tests

Unit tests and integration tests are run automatically on CI using the following command:

- **How to Test Locally:**
  ```bash
    cargo test

Make sure your code passes all tests before pushing.