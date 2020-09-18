provider "aws" {
}

resource "random_id" "id" {
  byte_length = 8
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "trust_current_account" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "breakglass_role" {
  assume_role_policy = data.aws_iam_policy_document.trust_current_account.json
}

resource "aws_iam_role_policy" "breakglass_permissions" {
  role = aws_iam_role.breakglass_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:List*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_cloudwatch_event_rule" "breakglass" {

  event_pattern = <<PATTERN
{
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
"detail": {
    "eventName": [
      "AssumeRole"
    ],
    "eventSource": [
      "sts.amazonaws.com"
    ],
    "requestParameters": {
      "roleArn": [
        "${aws_iam_role.breakglass_role.arn}"
      ]
    }
}
}
PATTERN
}

resource "aws_cloudwatch_event_target" "sqs" {
  rule      = aws_cloudwatch_event_rule.breakglass.name
  target_id = "SQS"
  arn       = aws_sqs_queue.queue.arn
  sqs_target {
    message_group_id = "1"
  }
}

resource "aws_sqs_queue" "queue" {
  name                        = "queue-${random_id.id.hex}.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

resource "aws_sqs_queue_policy" "test" {
  queue_url = aws_sqs_queue.queue.id

  policy = <<POLICY
{
	"Version": "2012-10-17",
	"Id": "sqspolicy",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				 "Service": "events.amazonaws.com"
			},
			"Action": "sqs:SendMessage",
			"Resource": "${aws_sqs_queue.queue.arn}",
			"Condition": {
				"ArnEquals": {
					"aws:SourceArn": "${aws_cloudwatch_event_rule.breakglass.arn}"
				}
			}
		}
	]
}
POLICY
}

output "queue" {
  value = aws_sqs_queue.queue.id
}

output "role" {
  value = aws_iam_role.breakglass_role.arn
}
