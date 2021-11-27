package persistance

const (
	DEBUG = false
)

type Persister interface {
	ID() string
	SetId(id string)

	GetName() string
	SetName(name string)

	LoadFile(path string, name string) (content string)
	SaveFile(path string, name string, content string) (string, string, error)

	CreatePersister(name string, id string) (Persister, error)
	InitPersister() (Persister, error)
	ClosePersister() error
	GetPersister() (interface{}, error)

}