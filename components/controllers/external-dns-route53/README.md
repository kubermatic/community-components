## external-dns-route53

This is a helm chart to deploy external-dns to work with a route53 zone.
You have to create an iam policy that allows external-dns to manage the zone and supply the credentials and domain name via values.

This is an example IAM policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
```

Please consider scoping the policy to the exact hosted zone that you intend to use.