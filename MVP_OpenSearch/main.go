package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/opensearch-project/opensearch-go"
	requestsigner "github.com/opensearch-project/opensearch-go/v2/signer/awsv2"
)

type Role_details struct {
	Reserved           bool     `json:"reserved"`
	Hidden             bool     `json:"hidden"`
	ClusterPermissions []string `json:"cluster_permissions"`
	IndexPermissions   []struct {
		IndexPatterns  []string `json:"index_patterns"`
		Fls            []string `json:"fls"`
		MaskedFields   []string `json:"masked_fields"`
		AllowedActions []string `json:"allowed_actions"`
	} `json:"index_permissions"`
	TenantPermissions []string `json:"tenant_permissions"`
	Static            bool     `json:"static"`
}

type roleMapping_details struct {
	Hosts           []string `json:"hosts"`
	Users           []string `json:"users"`
	Reserved        bool     `json:"reserved"`
	Hidden          bool     `json:"hidden"`
	BackendRoles    []string `json:"backend_roles"`
	AndBackendRoles []string `json:"and_backend_roles"`
}

type create_roleMapping_details struct {
	Hosts           []string `json:"hosts"`
	Users           []string `json:"users"`
	BackendRoles    []string `json:"backend_roles"`
	AndBackendRoles []string `json:"and_backend_roles"`
}

func get_role_mapping(client *opensearch.Client) {
	body := strings.NewReader(`{}`)
	httpreq, err := http.NewRequest("GET", "https://search-yasirutestdb-aksyu2uo6khdhuchy4v6ocyrai.eu-central-1.es.amazonaws.com/_plugins/_security/api/rolesmapping", body)
	if err != nil {
		log.Print(err.Error())
		return
	}
	httpreq.Header.Add("Content-Type", "application/json")
	resp, err := client.Perform(httpreq)
	if err != nil {
		log.Print(err.Error())
		return
	}
	p, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Print(err.Error())
	}
	v := map[string]roleMapping_details{}
	unmarsh_err := json.Unmarshal(p, &v)
	if unmarsh_err != nil {
		log.Print(unmarsh_err.Error())
		return
	}
	log.Print(v["security_manager"].BackendRoles)

}

func create_role_mapping(client *opensearch.Client, role_name string) {
	role_mapping := create_roleMapping_details{
		Hosts:           []string{},
		BackendRoles:    []string{"ARN::abc"},
		Users:           []string{},
		AndBackendRoles: []string{},
	}
	json_text, err := json.Marshal(role_mapping)
	body := strings.NewReader(string(json_text))
	httpreq, err := http.NewRequest("PUT", `https://search-yasirutestdb-aksyu2uo6khdhuchy4v6ocyrai.eu-central-1.es.amazonaws.com/_plugins/_security/api/rolesmapping/`+role_name, body)
	if err != nil {
		log.Print(err.Error())
		return
	}
	httpreq.Header.Add("Content-Type", "application/json")
	resp, err := client.Perform(httpreq)
	if err != nil {
		log.Print(err.Error())
		return
	}
	p, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Print(err.Error())
	}
	log.Print(string(p))
}

func get_roles(client *opensearch.Client) {
	body := strings.NewReader(`{}`)
	httpreq, err := http.NewRequest("GET", "https://search-yasirutestdb-aksyu2uo6khdhuchy4v6ocyrai.eu-central-1.es.amazonaws.com/_plugins/_security/api/roles/", body)
	httpreq.Header.Add("Content-Type", "application/json")
	resp, err := client.Perform(httpreq)
	if err != nil {
		log.Print(err)
		return
	}
	p, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Print(err.Error())
	}
	v := map[string]Role_details{}
	unmarsh_err := json.Unmarshal(p, &v)
	if unmarsh_err != nil {
		log.Print(unmarsh_err.Error())
		return
	}
	log.Print(v["alerting_full_access"])
}

func create_role(client *opensearch.Client) {

}

func main() {
	//var id string = "AWS Key ID"
	//var secret = "AWS key Secret"
	//var token = "AWS token"
	//credential := credentials.NewStaticCredentials(id, secret, token)
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion("eu-central-1"),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider("AKID", "SECRET_KEY", "TOKEN")),
	)

	if err != nil {
		log.Fatalf("failed to load configuration, %v", err)
	}
	fmt.Printf("cfg.Credentials: %v\n", cfg.Credentials)
	signer, err := requestsigner.NewSigner(cfg)
	if err != nil {
		log.Println(err.Error())
		return
	}

	client, err := opensearch.NewClient(opensearch.Config{
		Addresses: []string{"https://search-yasirutestdb-aksyu2uo6khdhuchy4v6ocyrai.eu-central-1.es.amazonaws.com/"},
		Signer:    signer,
	})
	if err != nil {
		log.Printf("err: %s\n", err.Error())
		return
	}
	//index_name := "movies"

	// create an index
	/*if resp, err := client.Indices.Create(index_name, client.Indices.Create.WithWaitForActiveShards("1")); err != nil {
		log.Fatal("indices.create: ", err)
	} else {
		log.Print(resp)
	}
	*/
	// Define index settings.
	/*settings := strings.NewReader(`{
	'settings': {
	  'index': {
		   'number_of_shards': 1,
		   'number_of_replicas': 2
		   }
		 }
	}`)
	*/
	/*req := opensearchapi.IndicesCreateRequest{
		Index: "tenant-1",
		Body:  settings,
	}*/
	/*resp, err := req.Do(context.TODO(), client.Transport)
	if err != nil {
		log.Print(err.Error())
	}
	log.Print(resp.StatusCode)
	*/
	// Define index settings.
	get_roles(client)
	get_role_mapping(client)
	create_role_mapping(client, "yasiru-test")
	//log.Println(client.Indices.GetMapping())
	//log.Println(client.Indices.Exists([]string{index_name}))
	//log.Println(client.Indices.Delete([]string{index_name}))
	//log.Println(client.Exists(index_name, "b"))
	//client.API.Get("abc", "a1")

}
