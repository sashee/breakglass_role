QUEUE_URL=$(terraform output queue)
while sleep 1; do \
	(MSG=$(aws sqs receive-message --queue-url $QUEUE_URL); \
		[ ! -z "$MSG"  ] && echo "$MSG" | jq -r '.Messages[] | .ReceiptHandle' | \
			(xargs -I {} aws sqs delete-message --queue-url $QUEUE_URL --receipt-handle {}) && \
		echo "$MSG" | jq -r '.Messages[] | .Body') \
; done
