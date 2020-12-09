package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"

	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func login() (*kubernetes.Clientset, string) {
	config, err := rest.InClusterConfig()
	if err != nil {
		panic(fmt.Sprintf("could not perform in cluster configuration of kubernetes: %v", err))
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}
	request := struct {
		JWT  string `json:"jwt"`
		Role string `json:"role"`
	}{config.BearerToken, os.Getenv("MAPPER_ROLE")}
	buffer := &bytes.Buffer{}
	if err := json.NewEncoder(buffer).Encode(&request); err != nil {
		panic(err)
	}
	req, err := http.NewRequest(http.MethodPost, os.Getenv("VAULT_ADDR")+"v1/auth/kubernetes/login", buffer)
	if err != nil {
		panic(err)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		panic(err)
	}
	if resp.StatusCode != http.StatusOK {
		s, _ := ioutil.ReadAll(resp.Body)
		panic(fmt.Sprintf("unexpected status code: %v. Returned: %v", resp.StatusCode, string(s)))
	}
	response := struct {
		Auth struct {
			Token string `json:"client_token"`
		} `json:"auth"`
	}{}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		panic(err)
	}
	if response.Auth.Token == "" {
		panic("did not receive a token")
	}
	_ = resp.Body.Close()
	return clientset, response.Auth.Token
}

func main() {
	clientset, vaultToken := login()
	for _, mapping := range strings.Fields(os.Getenv("MAPPER_MAPPINGS")) {
		parts := strings.Split(mapping, "=")
		k8sName := parts[0]
		vaultName := parts[1]
		vaultNameParts := strings.Split(vaultName, "/")
		req, err := http.NewRequest(http.MethodGet, os.Getenv("VAULT_ADDR")+"v1/"+vaultNameParts[0]+"/data/"+strings.Join(vaultNameParts[1:], "/"), nil)
		if err != nil {
			panic(err)
		}
		req.Header.Add("X-Vault-Token", vaultToken)
		secret := struct {
			Data struct {
				Data map[string]string `json:"data"`
			} `json:"data"`
			Errors []string `json:"errors"`
		}{}
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			panic(err)
		}
		if err := json.NewDecoder(resp.Body).Decode(&secret); err != nil {
			panic(err)
		}
		if secret.Errors != nil && len(secret.Errors) != 0 {
			panic(fmt.Sprintf("%v\n", secret.Errors))
		}
		_ = resp.Body.Close()
		s := &v1.Secret{
			StringData: map[string]string{},
		}
		s.ObjectMeta.Name = k8sName
		for key, value := range secret.Data.Data {
			fmt.Printf("found key %s for %s\n", key, k8sName)
			s.StringData[key] = value
		}
		_, err = clientset.CoreV1().Secrets(os.Getenv("MAPPER_NAMESPACE")).Create(context.Background(), s, metav1.CreateOptions{})
		if errors.IsAlreadyExists(err) {
			if _, err := clientset.CoreV1().Secrets(os.Getenv("MAPPER_NAMESPACE")).Update(context.Background(), s, metav1.UpdateOptions{}); err != nil {
				panic(err)
			}
		} else if err != nil {
			panic(err)
		}
	}
}
