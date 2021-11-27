package persistance

import (
	"fmt"
	"os"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

const (

)

func TestKonvert(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Persist Test Suite")
}

var _ = BeforeSuite(func() {
	if DEBUG {
		environ := os.Environ()

		for _, v := range environ {
			fmt.Printf("%s\n", v)
		}
	}
})

var _ = AfterSuite(func() {

})

var _ = Describe("Persist tests", func() {

})