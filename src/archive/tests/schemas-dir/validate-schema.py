#!/usr/bin/env python3
"""
Validate a JSON file against a JSON Schema.

Usage: validate-schema.py SCHEMA.json DATA.json

Exit codes:
  0 - Validation passed
  1 - Validation failed
  2 - Usage error (wrong arguments)
  3 - File error (cannot read files)
"""

import sys
import json

def main():
    if len(sys.argv) != 3:
        print("Usage: validate-schema.py SCHEMA.json DATA.json", file=sys.stderr)
        sys.exit(2)

    schema_path = sys.argv[1]
    data_path = sys.argv[2]

    # Import jsonschema here to give helpful error if not installed
    try:
        from jsonschema import validate, ValidationError, SchemaError
    except ImportError:
        print("Error: jsonschema not installed. Run: pip3 install jsonschema", file=sys.stderr)
        sys.exit(3)

    # Load schema
    try:
        with open(schema_path, 'r') as f:
            schema = json.load(f)
    except FileNotFoundError:
        print(f"Error: Schema file not found: {schema_path}", file=sys.stderr)
        sys.exit(3)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in schema: {e}", file=sys.stderr)
        sys.exit(3)

    # Load data
    try:
        with open(data_path, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Data file not found: {data_path}", file=sys.stderr)
        sys.exit(3)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in data: {e}", file=sys.stderr)
        sys.exit(3)

    # Validate
    try:
        validate(instance=data, schema=schema)
        print(f"Validation passed: {data_path}")
        sys.exit(0)
    except SchemaError as e:
        print(f"Schema error: {e.message}", file=sys.stderr)
        sys.exit(3)
    except ValidationError as e:
        print(f"Validation failed: {e.message}", file=sys.stderr)
        print(f"Path: {' -> '.join(str(p) for p in e.absolute_path)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
