# schma

Schma is a simple command line tool for validating JSON and YAML.

## Usage

```bash
> schma validate --schema schema.json --data data.json
```

Or from standard input:

```bash
> cat data.yaml | schma validate --schema schema.json
```

## License

[MIT](LICENSE)
