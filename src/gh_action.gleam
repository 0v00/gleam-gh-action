import argv
import envoy
import gleam/dynamic
import gleam/hackney
import gleam/http
import gleam/http/request
import gleam/io
import gleam/json
import gleam/list
import gleam/regex
import gleam/result
import gleeunit/should

pub type PullRequestFile {
  PullRequestFile(
    sha: String,
    filename: String,
    status: String,
    changes: Int,
    blob_url: String,
    raw_url: String,
    contents_url: String,
  )
}

fn get_auth_token() -> String {
  let assert Ok(auth_token) = envoy.get("TEST_SECRET")
  auth_token
}

fn get_pr_files(pr_id: String) {
  let owner = "SOME_OWNER"
  let repo = "SOME_REPO"
  let base_url = "https://api.github.com"
  let pr_files_req_path =
    "/repos/" <> owner <> "/" <> repo <> "/pulls/" <> pr_id <> "/files"
  let token = get_auth_token()
  let auth_token = "Bearer " <> token

  let assert Ok(request) = request.to(base_url <> pr_files_req_path)

  use response <- result.try(
    request
    |> request.prepend_header("Accept", "application/vnd.github+json")
    |> request.prepend_header("Authorization", auth_token)
    |> request.prepend_header("X-GitHub-Api-Version", "2022-11-28")
    |> hackney.send,
  )

  response.status
  |> should.equal(200)

  Ok(response.body)
}

fn make_comment(pr_id: String) {
  let owner = "0v00"
  let repo = "gha-test"
  let base_url = "https://api.github.com"
  let comment_path =
    "/repos/" <> owner <> "/" <> repo <> "/issues/" <> pr_id <> "/comments"
  let token = get_auth_token()
  let auth_token = "Bearer " <> token

  let assert Ok(request) = request.to(base_url <> comment_path)

  let body =
    json.to_string(
      json.object([#("body", json.string("Writing a comment using Gleam."))]),
    )

  use response <- result.try(
    request
    |> request.set_method(http.Post)
    |> request.prepend_header("Accept", "application/vnd.github+json")
    |> request.prepend_header("Authorization", auth_token)
    |> request.prepend_header("X-GitHub-Api-Version", "2022-11-28")
    |> request.set_body(body)
    |> hackney.send,
  )

  response.status
  |> should.equal(201)

  Ok(response)
}

fn parse_pr_files(json_string: String) {
  json.decode(
    json_string,
    dynamic.list(dynamic.decode7(
      PullRequestFile,
      dynamic.field("sha", dynamic.string),
      dynamic.field("filename", dynamic.string),
      dynamic.field("status", dynamic.string),
      dynamic.field("changes", dynamic.int),
      dynamic.field("blob_url", dynamic.string),
      dynamic.field("raw_url", dynamic.string),
      dynamic.field("contents_url", dynamic.string),
    )),
  )
}

pub fn main() {
  case argv.load().arguments {
    ["pr", pr_id] ->
      io.println(
        "pr_id found: " <> pr_id <> ". " <> "Proceeding with action...",
      )
    _ -> panic as "Missing arg: pr_id. See the README on how to fix this error."
  }

  let action_args = argv.load().arguments

  let pr_id = list.last(action_args) |> result.unwrap("")

  let assert Ok(re) = regex.from_string("^[0-9]+$")
  case regex.check(with: re, content: pr_id) {
    True -> io.println("pr_id passed regex check. Proceeding with action...")
    False -> panic as "pr_id failed regex check. Stopping."
  }

  let response_body =
    get_pr_files(pr_id)
    |> result.unwrap("")

  case parse_pr_files(response_body) {
    Ok(pr_files) -> {
      list.each(pr_files, fn(file) { io.println("Filename: " <> file.filename) })
    }
    Error(_error) -> io.println("Error.")
  }

  make_comment(pr_id)
}
