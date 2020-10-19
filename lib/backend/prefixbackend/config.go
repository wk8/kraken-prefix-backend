package prefixbackend

type Config struct {
	PrefixRegex string                 `yaml:"prefix_regex"`
	Backend     map[string]interface{} `yaml:"backend"`
}
