package prefixbackend

import (
	"io"
	"regexp"
	"strings"

	"github.com/pkg/errors"
	"github.com/uber/kraken/core"
	"github.com/uber/kraken/lib/backend"
	"gopkg.in/yaml.v2"
)

const _prefix = "prefix"

func init() {
	backend.Register(_prefix, &factory{})
}

type factory struct{}

func (*factory) Create(confRaw interface{}, authConfRaw interface{}) (backend.Client, error) {
	confBytes, err := yaml.Marshal(confRaw)
	if err != nil {
		return nil, errors.New("marshal prefix config")
	}
	var config Config
	if err := yaml.Unmarshal(confBytes, &config); err != nil {
		return nil, errors.New("unmarshal prefix config")
	}
	return NewClient(config, authConfRaw)
}

// Client implements a github.com/uber/kraken/lib/backend.Client that wraps another
// backend by removing a prefix from tag names
// (see https://github.com/uber/kraken/issues/278).
type Client struct {
	prefixRegex *regexp.Regexp
	backend     backend.Client
}

var _ backend.Client = &Client{}

// NewClient creates a new prefix Client.
func NewClient(config Config, authConfRaw interface{}) (*Client, error) {
	regex, err := compilePrefixRegex(config)
	if err != nil {
		return nil, err
	}

	backend, err := buildWrappedBackend(config, authConfRaw)
	if err != nil {
		return nil, err
	}

	return &Client{
		prefixRegex: regex,
		backend:     backend,
	}, nil
}

func compilePrefixRegex(config Config) (*regexp.Regexp, error) {
	rawRegex := config.PrefixRegex
	if !strings.HasPrefix(rawRegex, "^") {
		rawRegex = "^" + rawRegex
	}

	regex, err := regexp.Compile(rawRegex)
	return regex, errors.Wrapf(err, "unable to compile regex %q", rawRegex)
}

func buildWrappedBackend(config Config, authConfRaw interface{}) (backend.Client, error) {
	if len(config.Backend) != 1 {
		return nil, errors.New("no backend or more than one backend configured")
	}

	var (
		backendName   string
		backendConfig interface{}
	)
	for backendName, backendConfig = range config.Backend {
	}

	factory, err := backend.GetFactory(backendName)
	if err != nil {
		return nil, errors.Wrapf(err, "unknown backend type %q", backendName)
	}

	backend, err := factory.Create(backendConfig, authConfRaw)
	return backend, errors.Wrapf(err, "unable to create wrapped backend of type %q", backendName)
}

func (c *Client) Stat(namespace, name string) (*core.BlobInfo, error) {
	trimmedNamespace, trimmedName := c.trimPrefixFromNames(namespace, name)
	return c.backend.Stat(trimmedNamespace, trimmedName)
}

func (c *Client) Upload(namespace, name string, src io.Reader) error {
	trimmedNamespace, trimmedName := c.trimPrefixFromNames(namespace, name)
	return c.backend.Upload(trimmedNamespace, trimmedName, src)
}

func (c *Client) Download(namespace, name string, dst io.Writer) error {
	trimmedNamespace, trimmedName := c.trimPrefixFromNames(namespace, name)
	return c.backend.Download(trimmedNamespace, trimmedName, dst)
}

func (c *Client) List(prefix string, opts ...backend.ListOption) (*backend.ListResult, error) {
	return c.backend.List(c.trimPrefixFromString(prefix), opts...)
}

func (c *Client) trimPrefixFromNames(namespace, name string) (trimmedNamespace, trimmedName string) {
	trimmedNamespace = c.trimPrefixFromString(namespace)

	splitName := strings.SplitN(name, ":", 2)
	if len(splitName) == 2 {
		splitName[0] = c.trimPrefixFromString(splitName[0])
		trimmedName = strings.Join(splitName, ":")
	} else {
		trimmedName = name
	}

	return
}

func (c *Client) trimPrefixFromString(input string) string {
	return c.prefixRegex.ReplaceAllString(input, "")
}
