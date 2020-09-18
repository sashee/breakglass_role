# Sample code for a breakglass role with Terraform

## What is a breakglass role?

It's a role that sends a notification when it's used. It is useful for admin tasks that are rare but high impact, such as changing a KMS key permissions.

A breakglass role does not prevent doing an action but it notifies everybody (such as sending a message to a Slack channel and an email to the internal security address). This allows the security team to immediately know that something is wrong.

## How to use it

### Prerequisities

* terraform
* jq

### Deploy

You need to have CloudTrail enabled in the account.

* ```terraform init```
* ```terraform apply```

### Use

In one terminal watch the logs:

```./watch_logs.sh```

This fetches an SQS queue and prints any messages to the console.

In another terminal assume the role:

```aws sts assume-role --role-arn "$(terraform output role)" --role-session-name "test"```

In a few seconds you'll see the event in the first terminal.

### Cleanup

* ```terraform destroy```
