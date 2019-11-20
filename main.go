package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"

	"github.com/pkg/errors"

	"github.com/ghodss/yaml"
	"github.com/spf13/cobra"
	"github.com/xeipuuv/gojsonschema"
)

// These values are overridden by -ldflags
var (
	Version = "unknown"
)

// Cobra commands and flags
var (
	rootCmd = &cobra.Command{
		Use:     "schma",
		Version: Version,
		Short:   "Command line JSON schema tool",
	}

	versionCmd = &cobra.Command{
		Use:     "version",
		Version: Version,
		Short:   "Tool version",
		Run: func(c *cobra.Command, args []string) {
			fmt.Println(Version)
		},
	}

	validateCmd = &cobra.Command{
		Use:     "validate",
		Version: Version,
		Short:   "Validate JSON or YAML data against a JSON schema",
		RunE: func(c *cobra.Command, args []string) error {
			return validate()
		},
	}

	schemaFile string
	dataFile   string
)

func init() {
	rootCmd.AddCommand(versionCmd)
	rootCmd.AddCommand(validateCmd)
	validateCmd.Flags().StringVarP(&schemaFile, "schema", "s", "", "JSON schema file to validate against")
	validateCmd.Flags().StringVarP(&dataFile, "data", "d", "", "Data file to be validated (stdin is used if not specified)")

	_ = validateCmd.MarkFlagRequired("schema")
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func validate() error {
	var dataReader *bufio.Reader
	if dataFile == "" {
		dataReader = bufio.NewReader(os.Stdin)
	} else {
		f, err := os.Open(dataFile)
		if err != nil {
			return errors.Wrapf(err, "could not open %s", dataFile)
		}
		dataReader = bufio.NewReader(f)
	}

	data, err := ioutil.ReadAll(dataReader)
	if err != nil {
		return errors.Wrapf(err, "could not read input data")
	}

	data, err = yaml.YAMLToJSON(data)
	if err != nil {
		return errors.Wrapf(err, "could not convert YAML input data to JSON")
	}

	schema, err := ioutil.ReadFile(schemaFile)
	if err != nil {
		return errors.Wrapf(err, "could not read schema")
	}

	sl := gojsonschema.NewBytesLoader(schema)
	dl := gojsonschema.NewBytesLoader(data)
	result, err := gojsonschema.Validate(sl, dl)
	if err != nil {
		return err
	}

	if !result.Valid() {
		fmt.Println("Document is not valid. Errors:")
		for _, e := range result.Errors() {
			fmt.Printf("- %s\n", e)
		}
		os.Exit(1)
	}

	fmt.Println("Document is valid")
	return nil
}
