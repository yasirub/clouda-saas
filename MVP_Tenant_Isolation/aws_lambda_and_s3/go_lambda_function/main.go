package main

import (
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cognitoidentity"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/sts"
)

func exitErrorf(msg string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, msg+"\n", args...)
	os.Exit(1)
}

var sess *(session.Session)
var err error
var svc *(s3.S3)

func cognito_identiy_GetId(token string) *cognitoidentity.Credentials {
	svc := cognitoidentity.New(sess)
	logins := make(map[string]*string)
	logins["cognito-idp.eu-west-2.amazonaws.com/eu-west-2_ypy2SeovU"] = &token
	input := &cognitoidentity.GetIdInput{
		AccountId:      aws.String("210226302225"),
		IdentityPoolId: aws.String("eu-west-2:31716ca8-a2d0-492e-91a7-7c3a261af441"),
		Logins:         logins,
	}
	result, err := svc.GetId(input)
	if err != nil {
		log.Println(err.Error())
	} else {
		//log.Println(*result.IdentityId)
	}
	getCredentialsForIdentityInput := &cognitoidentity.GetCredentialsForIdentityInput{
		IdentityId: result.IdentityId,
		Logins:     logins,
	}
	getCredentialsForIdentityOutput, err := svc.GetCredentialsForIdentity(getCredentialsForIdentityInput)
	if err != nil {
		log.Println(err.Error())
	} else {
		log.Println(*getCredentialsForIdentityOutput)
	}
	return getCredentialsForIdentityOutput.Credentials
	//this getOpenIdToken dosent work with role mapping enabled
	/*getOpenIdTokenInput := &cognitoidentity.GetOpenIdTokenInput{
		IdentityId: result.IdentityId,
		Logins:     logins,
	}

	getOpenIdTokenOutput, err := svc.GetOpenIdToken(getOpenIdTokenInput)
	if err != nil {
		log.Println(err.Error())
	} else {
		//log.Println(*getOpenIdTokenOutput.Token)
	}
	return *getOpenIdTokenOutput.Token
	*/
}

func sts_AssumeRoleWithWebIdentity(token string) {
	svc := sts.New(sess)
	input := &sts.AssumeRoleWithWebIdentityInput{
		DurationSeconds: aws.Int64(3600),
		Policy:          aws.String("{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"Stmt1\",\"Effect\":\"Allow\",\"Action\":\"s3:ListAllMyBuckets\",\"Resource\":\"*\"}]}"),
		//ProviderId:       aws.String("www.amazon.com"),
		RoleArn:          aws.String("arn:aws:iam::123456789012:role/FederatedWebIdentityRole"),
		RoleSessionName:  aws.String("s3-access"),
		WebIdentityToken: aws.String(token),
	}
	result, err := svc.AssumeRoleWithWebIdentity(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case sts.ErrCodeMalformedPolicyDocumentException:
				log.Println(sts.ErrCodeMalformedPolicyDocumentException, aerr.Error())
			case sts.ErrCodePackedPolicyTooLargeException:
				log.Println(sts.ErrCodePackedPolicyTooLargeException, aerr.Error())
			case sts.ErrCodeIDPRejectedClaimException:
				log.Println(sts.ErrCodeIDPRejectedClaimException, aerr.Error())
			case sts.ErrCodeIDPCommunicationErrorException:
				log.Println(sts.ErrCodeIDPCommunicationErrorException, aerr.Error())
			case sts.ErrCodeInvalidIdentityTokenException:
				log.Println(sts.ErrCodeInvalidIdentityTokenException, aerr.Error())
			case sts.ErrCodeExpiredTokenException:
				log.Println(sts.ErrCodeExpiredTokenException, aerr.Error())
			case sts.ErrCodeRegionDisabledException:
				log.Println(sts.ErrCodeRegionDisabledException, aerr.Error())
			default:
				log.Println(aerr.Error())
			}
		} else {
			// Print the error, cast err to awserr.Error to get the Code and
			// Message from an error.
			log.Println(err.Error())
		}
		return
	}

	log.Println(result)
}

func main() {
	sess, err = session.NewSession(&aws.Config{
		Region: aws.String("eu-west-2")},
	)

	if err != nil {
		log.Println(err.Error())
	}
	svc = s3.New(sess)

	log.Println(svc.APIVersion)
	lambda.Start(handler)
}

func handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	token := request.Headers["authorization"]
	creds := cognito_identiy_GetId(token)
	//sts_AssumeRoleWithWebIdentity(openId_token)
	log.Println("Hello world")
	svc.Config.Credentials = credentials.NewStaticCredentials(*creds.AccessKeyId, *creds.SecretKey, *creds.SessionToken)
	result, err := svc.ListBuckets(nil)
	if err != nil {
		log.Printf("Unable to list buckets, %v \n", err)
	} else {
		for _, b := range result.Buckets {
			fmt.Printf("* %s created on %s\n",
				aws.StringValue(b.Name), aws.TimeValue(b.CreationDate))
		}
	}
	result_ls, err := svc.ListObjectsV2(&s3.ListObjectsV2Input{Bucket: aws.String("saas-tenant-isolation")})
	if err != nil {
		log.Printf("Unable to list items in bucket %q, %v", "saas-tenant-isolation", err)
	} else {
		for _, item := range result_ls.Contents {
			log.Println("Name:         ", *item.Key)
			log.Println("Last modified:", *item.LastModified)
			log.Println("Size:         ", *item.Size)
			log.Println("Storage class:", *item.StorageClass)
			log.Println("")
		}
	}
	response := events.APIGatewayProxyResponse{
		StatusCode: 200,
	}
	if request.Path == "/v1/s3" {
		if request.HTTPMethod == "GET" {
			response.Body = "{msg: Hello I'm new Get endpoint}"
			log.Println("This is get request")
		} else if request.HTTPMethod == "POST" {
			response.Body = "{msg: Hello I'm new Post endpoint}"
			log.Println("this is post request")
		} else if request.HTTPMethod == "DELETE" {
			response.Body = "{msg: Hello I'm new Delete endpoint}"
			log.Println("This is get Delete request")
		} else {
			log.Println("this is default")
		}
	}

	log.Println(request.RequestContext.AccountID)

	return response, nil
}
