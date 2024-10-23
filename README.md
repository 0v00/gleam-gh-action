# Gleam Docker Container Action

This is a simple example of creating a GitHub Docker container action using Gleam. The code is probably not very idiomatic Gleam.

Usage in your `workflow.yml` file:

```yml
name: Gleam PR Check

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  run-gleam-and-process-pr:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Gleam and Process PR
        uses: OWNER/REPO@BRANCH
        env:
          TEST_SECRET: ${{ secrets.TEST_SECRET }}
        with:
          pr_id: ${{ github.event.pull_request.number }}
```