# Code Quality Guidelines

This document outlines the tools and standards used to maintain code quality in this project. Please follow these guidelines to ensure the codebase remains clean, efficient, and secure.

## Quality Tools

### Clippy

[Clippy](https://doc.rust-lang.org/clippy/usage.html) is a Rust linter that provides a collection of lints to catch common mistakes and improve code quality.

**How to Run Clippy Locally:**  
  ```bash
  cargo clippy -- -D warnings
  ```
The -D warnings flag tells Clippy to deny all warnings. This will cause the build to fail if there are any warnings, ensuring that your codebase is free of common issues and follows best practices.  

**How to Fix Clippy Errors:**  
  1. Review the message Clippy provides. It typically points to the specific line of code and describes the issue.
  2. Fix the reported issue manually. Clippy often provides suggestions or hints about how to resolve the issue (e.g., removing unused variables, changing inefficient code patterns).

**Automatically Fix Simple Clippy Issues:**  
  Some common Clippy warnings can be automatically fixed using the cargo fix command:
 ```bash  
  cargo fix --clippy
  ```   
This command will automatically apply fixes for the majority of Clippy lints that can be safely corrected. After running this command, you can re-run cargo clippy to verify that the issues have been resolved.

Clippy on CI: Clippy is run automatically as part of the CI process. The build will fail if any warnings or errors are found.

### Rustfmt

[Rustfmt](https://doc.rust-lang.org/clippy/development/adding_lints.html#running-rustfmt) automatically formats Rust code to conform to style guidelines.

**How to Run Rustfmt Locally:**
```bash
  cargo fmt -- --check
  ```

This command will not modify any files but will indicate if any files are not correctly formatted. If Rustfmt reports any differences, you can run to automatically format your code:
  ```bash
  cargo fmt
  ```

Rustfmt on CI: Rustfmt is run as part of the CI pipeline.

### Cargo Audit

[Cargo Audit](https://docs.rs/cargo-audit/latest/cargo_audit/) checks for known vulnerabilities in the dependencies of your project.

**How to Run Cargo Audit Locally:**
```bash
  cargo audit
```
This will audit your project’s dependencies and check for any known vulnerabilities. If vulnerabilities are found, you'll see details about the affected packages and versions.

**How to Fix Vulnerabilities:** 

```bash
  cargo update
```
In case an update doesn't resolve the issue, look for advice on upgrading to a non-vulnerable version or consider using alternative packages.

Cargo Audit on CI: Cargo Audit should be included in the CI pipeline to ensure that no vulnerabilities are introduced into the codebase. 

### Running Tests

Unit tests and integration tests are run automatically on CI using the following command:

**How to Test Locally:**
  ```bash
  cargo test
  ```
Tests on CI: All tests should be executed as part of the CI pipeline. If any tests fail, the build should fail.