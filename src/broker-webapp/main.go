package main

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"github.com/sirupsen/logrus"
	"github.com/spiffe/go-spiffe/v2/logger"
	"github.com/spiffe/go-spiffe/v2/spiffeid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	"broker-webapp/quotes"

	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

const (
	port              = 8080
	quotesURL         = "https://172.17.255.2:8090/quotes"
	target            = "172.17.255.2:8090"
	socketPath        = "unix:///run/spire/sockets/agent.sock"
	tlsContextTimeout = 5 * time.Second
)

var (
	latestQuotes = []*quotes.Quote(nil)
	latestUpdate = time.Now()
	// Stock quotes provider SPIFFE ID
	x509Src                *workloadapi.X509Source
	bundleSrc              *workloadapi.BundleSource
	clientTlxConfig        *tls.Config
)

func main() {
	log.Print("Webapp waiting for an X.509 SVID...")

	ctx := context.Background()

	var err error
	x509Src, err = workloadapi.NewX509Source(ctx,
		workloadapi.WithClientOptions(
			workloadapi.WithAddr(socketPath),
			workloadapi.WithLogger(logger.Std),
		),
	)
	if err != nil {
		log.Fatal(err)
	}

	clientTlxConfig, err = clientConfig(ctx)

	server := &http.Server{
		Addr: fmt.Sprintf(":%d", port),
	}
	http.HandleFunc("/quotes", quotesHandler)

	log.Printf("Webapp listening on port %d...", port)

	err = server.ListenAndServe()
	if err != nil {
		log.Fatal(err)
	}
}

func GetTLSConfigByID(id interface{}) (*tls.Config, error) {
	var trustDomain spiffeid.TrustDomain
	var err error

	if w, ok := id.(string); ok {
		trustDomain, err = spiffeid.TrustDomainFromString(w)
		if err != nil {
			return nil, err
		}
	}

	if w, ok := id.(spiffeid.TrustDomain); ok {
		trustDomain = w
	}

	bundleSrc, err := x509Src.GetX509BundleForTrustDomain(trustDomain)
	if err != nil {
		logrus.Error("Could not obtain trust domain bundle", err)
		return nil, err
	}

	authorizer := tlsconfig.AuthorizeAny()

	tlsConfig := tlsconfig.MTLSClientConfig(
		x509Src,
		bundleSrc,
		authorizer,
	)
	return tlsConfig, nil
}
func GetTLSConfigs(ctx context.Context) ([]*tls.Config, error) {
	var tlsConfigs []*tls.Config

	bundles, err := workloadapi.FetchX509Bundles(
		ctx,
		workloadapi.WithAddr(socketPath),
	)
	if err != nil {
		logrus.Error("Failed to fetch bundles", err)
		return nil, err
	}

	for _, bundle := range bundles.Bundles() {
		id := bundle.TrustDomain()
		logrus.Infof("id trustDomain: %s", id)
		tlsConfig, err := GetTLSConfigByID(ctx, id)
		if err != nil {
			logrus.Errorf("Failed to fetch tlsConfig for Trust Domain: %v", id)
			return nil, err
		}
		logrus.Infof("Fetch tlsConfig for Trust Domain: %v", id)
		tlsConfigs = append(tlsConfigs, tlsConfig)
	}

	return tlsConfigs, nil
}

func clientConfig(ctx context.Context) (*tls.Config, error) {
	tlsConfigs, err := GetTLSConfigs(ctx)
	if err != nil {
		logrus.Fatal(
			"Failed to retrieve tlsConfigs from security provider with error:",
			err.Error(),
		)
	}
	logrus.Infof("Retrived %d tlsconfigs", len(tlsConfigs))

	innerContext, cancelInnerContext := context.WithTimeout(context.TODO(), tlsContextTimeout)
	defer cancelInnerContext()

	tlsConfigChan := make(chan *tls.Config, 1)
	for _, tlsConfig := range tlsConfigs {
		go func(tlsConfig *tls.Config, tlsConfigChan chan<- *tls.Config) {
			conn, err := grpc.DialContext(
				innerContext,
				target,
				grpc.WithBlock(),
				grpc.WithTransportCredentials(credentials.NewTLS(tlsConfig)),
			)
			if err == nil {
				logrus.Infof("Found the right tls certificate for target: %v", target)
				tlsConfigChan <- tlsConfig
				_ = conn.Close()
				close(tlsConfigChan)
				cancelInnerContext()
				return
			}
		} (tlsConfig, tlsConfigChan)
	}

	var tlsConfig *tls.Config
	select {
	case tlsConfigRec := <- tlsConfigChan:
		tlsConfig = tlsConfigRec
	case <- time.After(tlsContextTimeout):
		logrus.Errorf("Failed to get the right certificate for target: %v", target)
		tlsConfig = nil
	}
	if tlsConfig == nil {
		logrus.Errorf("tls config is nil for target: %v", target)
		return nil, fmt.Errorf("tls config is nil for target: %v", target)
	}

	return tlsConfig, nil
}

func quotesHandler(resp http.ResponseWriter, req *http.Request) {
	if req.Method != http.MethodGet {
		resp.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	data, err := getQuotesData()

	if data != nil {
		latestQuotes = data
		latestUpdate = time.Now()
	} else {
		data = latestQuotes
	}

	quotes.Page.Execute(resp, map[string]interface{}{
		"Data":        data,
		"Err":         err,
		"LastUpdated": latestUpdate,
	})
}

func getQuotesData() ([]*quotes.Quote, error) {
	client := http.Client{
		Transport: &http.Transport{
			TLSClientConfig: clientTlxConfig,
		},
	}

	resp, err := client.Get(quotesURL)
	if err != nil {
		log.Printf("Error getting quotes: %v", err)
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		log.Printf("Quotes unavailables: %s", resp.Status)
		return nil, err
	}

	jsonData, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Error reading response body: %v", err)
		return nil, err
	}

	data := []*quotes.Quote{}
	err = json.Unmarshal(jsonData, &data)
	if err != nil {
		log.Printf("Error unmarshaling json quotes: %v", err)
		return nil, err
	}

	return data, nil
}
