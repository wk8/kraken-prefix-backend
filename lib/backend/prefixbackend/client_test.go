package prefixbackend

import (
	"testing"

	"github.com/uber/kraken/lib/backend/registrybackend"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	_ "github.com/uber/kraken/lib/backend/registrybackend"
)

var testConfig = Config{
	PrefixRegex: `a\.com/?`,
	Backend: map[string]interface{}{
		"registry_tag": map[string]interface{}{
			"address": "index.docker.io",
			"security": map[string]interface{}{
				"basic": map[string]interface{}{
					"username": "",
					"password": "",
				},
			},
		},
	},
}

func TestClientFactory(t *testing.T) {
	f := &factory{}
	rawClient, err := f.Create(testConfig, nil)
	require.NoError(t, err)

	client, ok := rawClient.(*Client)
	require.True(t, ok)
	assert.Equal(t, `^a\.com/?`, client.prefixRegex.String())

	_, ok = client.backend.(*registrybackend.TagClient)
	require.True(t, ok)
}

func TestTrimPrefixFromNames(t *testing.T) {
	client, err := NewClient(testConfig, nil)
	require.NoError(t, err)

	for _, testCase := range []struct {
		namespace, expectedTrimmedNamespace, name, expectedTrimmedName string
	}{
		{
			namespace:                "a.com/image:tag",
			expectedTrimmedNamespace: "image:tag",
			name:                     "image:tag",
			expectedTrimmedName:      "image:tag",
		},
		{
			namespace:                "a.com/image:tag",
			expectedTrimmedNamespace: "image:tag",
			name:                     "a.com/image:tag",
			expectedTrimmedName:      "image:tag",
		},
		{
			namespace:                "a.com/image:tag",
			expectedTrimmedNamespace: "image:tag",
			name:                     "a.com/image_tag",
			expectedTrimmedName:      "a.com/image_tag",
		},
	} {
		trimmedNamespace, trimmedName := client.trimPrefixFromNames(testCase.namespace, testCase.name)

		assert.Equal(t, testCase.expectedTrimmedNamespace, trimmedNamespace)
		assert.Equal(t, testCase.expectedTrimmedName, trimmedName)
	}
}
