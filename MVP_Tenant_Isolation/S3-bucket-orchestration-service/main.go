package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cognitoidentity"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/gin-gonic/gin"
)

var sess *(session.Session)
var err error
var svc *(s3.S3)

type msg struct {
	Msg   string `json:"msg"`
	Value string `json:"value"`
	From  string `json:"from cluster"`
}

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

func getrootRoute(c *gin.Context) {
	clusterColor := os.Getenv("cluster_color")
	msg := msg{Msg: "msg", Value: "hi this is root route", From: clusterColor}
	c.IndentedJSON(http.StatusOK, msg)
}

func listS3Buckets(c *gin.Context) {
	log.Println(c.Request.Header)
	token := c.Request.Header["Authorization"]

	creds := cognito_identiy_GetId(token[0])

	s3_svc := s3.New(sess)
	s3_svc.Config.Credentials = credentials.NewStaticCredentials(*creds.AccessKeyId, *creds.SecretKey, *creds.SessionToken)
	result, err := s3_svc.ListBuckets(nil)

	if err != nil {
		log.Printf("Unable to list buckets, %v \n", err)
	}
	list, err := json.Marshal(result.Buckets)
	msg := msg{Msg: "msg", Value: "hi this is root /s3", From: string(list)}
	c.IndentedJSON(http.StatusOK, msg)
}

func createS3Bucket(c *gin.Context) {

}

func deleteS3Bucket(c *gin.Context) {

}

func listObjectsInS3Bucket(c *gin.Context) {

}

func deleteObjectInS3Bucket(c *gin.Context) {

}

func main() {
	sess, err = session.NewSession(&aws.Config{
		Region: aws.String("eu-west-2")},
	)

	if err != nil {
		log.Println(err.Error())
	}
	router := gin.Default()
	router.GET("/", getrootRoute)
	router.GET("/s3", listS3Buckets)
	router.POST("/s3", createS3Bucket)
	router.DELETE("/s3/:id", deleteS3Bucket)
	router.GET("/s3/:id", listObjectsInS3Bucket)
	router.DELETE("/s3/:id/:objectid", deleteObjectInS3Bucket)
	router.Run("0.0.0.0:8080")
}
