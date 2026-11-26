# infra-lambda-budget-ledger-add

Terraform that deploys one AWS Lambda function,
[lambda-budget-ledger-add](https://github.com/iaireal/lambda-budget-ledger-add), and
nothing else.

The function's source code lives in that repository. This one never builds it: it
deploys a published release, chosen by version.

## What it creates

| Resource | Name | Notes |
| -------- | ---- | ----- |
| Lambda function | `budget-ledger-add` | Runtime `provided.al2023`, arm64, 128 MB, 3 second timeout |
| IAM role | `budget-ledger-add-lambda` | Only the Lambda service can use it. It can write to the function's own log group and do nothing else |
| CloudWatch log group | `/aws/lambda/budget-ledger-add` | Logs are kept for 14 days |

The function has no trigger. It runs only when someone invokes it directly.

## How a release gets deployed

1. A version tag in `lambda-budget-ledger-add` makes GitHub Actions publish a release
   with `bootstrap.zip` and its SHA-256 checksum.
2. `task download` fetches both files for the requested version into `artifacts/` and
   verifies the zip against the checksum.
3. Terraform uploads that zip to Lambda.

`task plan` runs the download, so step 2 rarely needs to be run by hand. The `artifacts/`
folder is not committed.

## Requirements

- Terraform 1.10 or later
- The AWS CLI, with a profile for the account to deploy into
- [Task](https://taskfile.dev)
- `curl` and `sha256sum`
- The account's Terraform state bucket, created by
  [infra-account-baseline](https://github.com/iaireal/infra-account-baseline)

There are no input files and no private values.

## Usage

Tasks that act on an AWS account take the AWS CLI profile of that account. The plan also
takes the release to deploy, without the leading `v`. Neither has a default.

```bash
task plan PROFILE=<aws-cli-profile> VERSION=0.1.0    # review the output
task apply PROFILE=<aws-cli-profile>                 # applies exactly the plan that was reviewed
task invoke PROFILE=<aws-cli-profile>                # prints {"sum":5}
```

| Task | What it does |
| ---- | ------------ |
| `task download VERSION=<release>` | Downloads the release and verifies its checksum |
| `task init PROFILE=<profile>` | Points Terraform at that account's state bucket |
| `task plan PROFILE=<profile> VERSION=<release>` | Runs `download` and `init`, shows what would change, saves it to `tfplan-<profile>` |
| `task apply PROFILE=<profile>` | Applies the saved plan for that profile, then deletes it |
| `task invoke PROFILE=<profile>` | Calls the deployed function with 2 and 3 and prints its answer |
| `task validate` | Checks formatting and validates the configuration |

### Deploying a new version

Run `task plan` with the new `VERSION` and apply it. Terraform replaces the function's
code and leaves the role and the log group as they are.

To go back to an earlier version, do the same with the earlier `VERSION`.

### Where the state is kept

Terraform state is stored in the bucket `iaireal-terraform-state-<account-id>` of the
account the function is deployed in, under the key
`infra-lambda-budget-ledger-add/terraform.tfstate`. The bucket name contains the account
ID, so `task init` looks it up instead of having it written in code.

## Things that can hurt

- **Never commit a state file or a saved plan.** `.gitignore` blocks them.
- **A saved plan is tied to the downloaded zip.** If `artifacts/` is deleted between
  `task plan` and `task apply`, the apply fails; run `task plan` again.
