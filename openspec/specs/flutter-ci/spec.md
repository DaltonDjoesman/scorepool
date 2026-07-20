# flutter-ci Specification

## Purpose
Continuous integration for Flutter analyze and tests on pull requests and default-branch pushes.

## Requirements

### Requirement: Flutter analyze and test on CI
The repository SHALL run Flutter static analysis and the unit/widget test suite on GitHub Actions for pull requests and pushes to the default branch.

#### Scenario: PR triggers Flutter CI
- **WHEN** a pull request targeting the default branch is opened or updated
- **THEN** a workflow job runs `flutter analyze` and `flutter test` and fails the check if either fails

### Requirement: CI uses a pinned Flutter toolchain
The Flutter CI workflow SHALL pin a Flutter version or channel so recruiter-visible checks are reproducible.

#### Scenario: Workflow declares Flutter version
- **WHEN** a reviewer opens the Flutter CI workflow file
- **THEN** it specifies an explicit Flutter version or stable channel pin via the setup action
