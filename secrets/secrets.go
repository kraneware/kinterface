package secrets

const (
	DEBUG = false
)

type SecretsKeeper interface {
	ID() string
	SetId(id string)

	GetName() string
	SetName(name string)

	LoadSecret(path string) (string, error)
	SaveSecret(path string, content string) error

	InitSecretsKeeper() error
	CloseSecretsKeeper() error
	GetConnection() (interface{}, error)
}
