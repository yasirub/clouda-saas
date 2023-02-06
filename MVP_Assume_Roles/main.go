package main

import (
	"context"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials/stscreds"
	"github.com/aws/aws-sdk-go-v2/service/sts"
)

func main() {
	// Initial credentials loaded from SDK's default credential chain. Such as
	// the environment, shared credentials (~/.aws/credentials), or EC2 Instance
	// Role. These credentials will be used to to make the STS Assume Role API.
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		panic(err)
	}

	// Create the credentials from AssumeRoleProvider to assume the role
	// referenced by the "myRoleARN" ARN.
	stsSvc := sts.NewFromConfig(cfg)
	creds := stscreds.NewAssumeRoleProvider(stsSvc, "arn:aws:iam::210226302225:role/A-opensearch-test-user-yb", func(o *stscreds.AssumeRoleOptions) {
		o.SourceIdentity = aws.String("opensearch-search-orchest")
	})

	cfg.Credentials = aws.NewCredentialsCache(creds)
	cred, err := cfg.Credentials.Retrieve(context.TODO())
	if err != nil {
		panic(err)
	}
	log.Print(cred)
}
