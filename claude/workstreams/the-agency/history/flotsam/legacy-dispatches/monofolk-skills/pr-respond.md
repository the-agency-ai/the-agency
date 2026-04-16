---
allowed-tools: Bash(git branch --show-current), Bash(gh pr list:*), Bash(gh repo view:*), Bash(gh api repos/*/pulls/*/comments:*), Bash(gh api repos/*/issues/*/comments:*), Bash(gh api repos/*/pulls/*/comments/*/replies --method POST*), Bash(gh api graphql*), Read, Glob, Grep
---

# PR Review Comment Responder

Fetch review comments on the current branch's PR, compose threaded replies, and resolve threads. Unlike `/pr-comments`, this command does NOT make code changes — it only responds.

## When to use

- Fixes were already made and you want to reply confirming them
- You want to explain why a suggestion was not adopted
- You want to ask a clarifying question on a review comment

## Instructions

1. **Find the PR** for the current branch:
   - Get the current branch with `git branch --show-current`
   - Get the repo owner/name with `gh repo view --json owner,name --jq '.owner.login + "/" + .name'`
   - Do NOT use `git remote` — it is not in the allowed-tools list. Always use `gh repo view` instead.
   - Run `gh pr list --head <current-branch> --json number,title --jq '.[0].number'` to get the PR number
   - If no PR exists, inform the user and stop

2. **Fetch unresolved review comments** via GraphQL (use variable binding to prevent injection):

   ```
   gh api graphql -F owner=<owner> -F repo=<repo> -F pr=<PR> -f query='query($owner:String!,$repo:String!,$pr:Int!) { repository(owner:$owner,name:$repo) { pullRequest(number:$pr) { reviewThreads(first: 50) { nodes { id isResolved comments(first: 10) { nodes { id databaseId path line body author { login } } } } } } } }' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | {threadId: .id, comments: [.comments.nodes[] | {id: .databaseId, path, line, body, user: .author.login}]}'
   ```

   - Also fetch issue-level comments: `gh api repos/<owner>/<repo>/issues/<PR>/comments --jq '.[] | {body: .body, user: .user.login}'`
   - If there are no unresolved threads, inform the user and stop

3. **Present all unresolved comments** in a numbered list:

   For each comment, show:
   - Comment number
   - Author
   - File and line (if review comment)
   - The comment body (full text)

4. **For each comment, determine the response**:
   - If the fix was already made: note what was changed
   - If the suggestion was valid but deferred: explain when it will be addressed
   - If the suggestion was not adopted: explain the reasoning
   - If you need user input, ask before replying

5. **Post threaded replies**:
   - To reply to a review comment: `gh api repos/<owner>/<repo>/pulls/<PR>/comments/<comment_id>/replies --method POST -f body="<message>"`
   - To reply to an issue comment: `gh api repos/<owner>/<repo>/issues/<PR>/comments --method POST -f body="<message>"`
   - Resolve each thread after replying (use variable binding):
     ```
     gh api graphql -F threadId=<thread_id> -f query='mutation($threadId:ID!) { resolveReviewThread(input: { threadId: $threadId }) { thread { isResolved } } }'
     ```

6. **Generate a summary report**:

| #   | File         | Comment           | Response         | Resolved |
| --- | ------------ | ----------------- | ---------------- | -------- |
| 1   | path/to/file | Brief description | What was replied | Yes/No   |

## Guidelines

- Always read the referenced file before responding — understand the context
- Be direct and specific in replies — avoid vague "will fix later" responses
- If a fix was made, reference the commit or describe the change
- Number your questions to the user so they can reply by number
