package canonical

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"reflect"
	"sort"
	"strings"
	"unicode/utf8"
)

const maxMachineJSONBytes = 1 << 20

type object map[string]any

// Encode converts a Go JSON-compatible value or strict RawMessage to canonical JSON.
func Encode(value any) ([]byte, error) {
	var data []byte
	var err error
	if raw, ok := value.(json.RawMessage); ok {
		data = bytes.Clone(raw)
	} else {
		if err := rejectFloatValues(reflect.ValueOf(value), make(map[visit]bool)); err != nil {
			return nil, err
		}
		data, err = json.Marshal(value)
		if err != nil {
			return nil, fmt.Errorf("marshal JSON value: %w", err)
		}
	}
	if len(data) > maxMachineJSONBytes {
		return nil, fmt.Errorf("machine JSON exceeds %d bytes", maxMachineJSONBytes)
	}
	if !utf8.Valid(data) {
		return nil, fmt.Errorf("machine JSON is not valid UTF-8")
	}
	parsed, err := parse(data)
	if err != nil {
		return nil, err
	}
	var output bytes.Buffer
	if err := writeValue(&output, parsed); err != nil {
		return nil, err
	}
	return output.Bytes(), nil
}

// Digest returns the SHA-256 digest of a value's canonical JSON bytes.
func Digest(value any) (string, error) {
	data, err := Encode(value)
	if err != nil {
		return "", err
	}
	digest := sha256.Sum256(data)
	return "sha256:" + hex.EncodeToString(digest[:]), nil
}

type visit struct {
	typ reflect.Type
	ptr uintptr
}

func rejectFloatValues(value reflect.Value, seen map[visit]bool) error {
	if !value.IsValid() {
		return nil
	}
	if value.Type() == reflect.TypeFor[json.RawMessage]() || value.Type() == reflect.TypeFor[json.Number]() {
		return nil
	}
	switch value.Kind() {
	case reflect.Float32, reflect.Float64:
		return fmt.Errorf("floating-point values are not supported")
	case reflect.Interface, reflect.Pointer:
		if value.IsNil() {
			return nil
		}
		if value.Kind() == reflect.Pointer {
			key := visit{typ: value.Type(), ptr: value.Pointer()}
			if seen[key] {
				return nil
			}
			seen[key] = true
		}
		return rejectFloatValues(value.Elem(), seen)
	case reflect.Map:
		if value.IsNil() {
			return nil
		}
		key := visit{typ: value.Type(), ptr: value.Pointer()}
		if seen[key] {
			return nil
		}
		seen[key] = true
		iter := value.MapRange()
		for iter.Next() {
			if err := rejectFloatValues(iter.Value(), seen); err != nil {
				return err
			}
		}
	case reflect.Slice:
		if value.IsNil() {
			return nil
		}
		key := visit{typ: value.Type(), ptr: value.Pointer()}
		if seen[key] {
			return nil
		}
		seen[key] = true
		for i := 0; i < value.Len(); i++ {
			if err := rejectFloatValues(value.Index(i), seen); err != nil {
				return err
			}
		}
	case reflect.Array:
		for i := 0; i < value.Len(); i++ {
			if err := rejectFloatValues(value.Index(i), seen); err != nil {
				return err
			}
		}
	case reflect.Struct:
		for i := 0; i < value.NumField(); i++ {
			field := value.Type().Field(i)
			if field.PkgPath != "" || field.Tag.Get("json") == "-" {
				continue
			}
			if err := rejectFloatValues(value.Field(i), seen); err != nil {
				return err
			}
		}
	}
	return nil
}

func parse(data []byte) (any, error) {
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.UseNumber()
	value, err := readValue(decoder)
	if err != nil {
		return nil, fmt.Errorf("parse machine JSON: %w", err)
	}
	if token, err := decoder.Token(); err != io.EOF {
		if err == nil {
			return nil, fmt.Errorf("trailing JSON token %v", token)
		}
		return nil, fmt.Errorf("parse trailing machine JSON: %w", err)
	}
	return value, nil
}

func readValue(decoder *json.Decoder) (any, error) {
	token, err := decoder.Token()
	if err != nil {
		return nil, err
	}
	switch value := token.(type) {
	case json.Delim:
		switch value {
		case '{':
			result := make(object)
			for decoder.More() {
				keyToken, err := decoder.Token()
				if err != nil {
					return nil, err
				}
				key, ok := keyToken.(string)
				if !ok {
					return nil, fmt.Errorf("object key is %T", keyToken)
				}
				if _, exists := result[key]; exists {
					return nil, fmt.Errorf("duplicate object key %q", key)
				}
				child, err := readValue(decoder)
				if err != nil {
					return nil, err
				}
				result[key] = child
			}
			end, err := decoder.Token()
			if err != nil {
				return nil, err
			}
			if end != json.Delim('}') {
				return nil, fmt.Errorf("object ended with %v", end)
			}
			return result, nil
		case '[':
			result := make([]any, 0)
			for decoder.More() {
				child, err := readValue(decoder)
				if err != nil {
					return nil, err
				}
				result = append(result, child)
			}
			end, err := decoder.Token()
			if err != nil {
				return nil, err
			}
			if end != json.Delim(']') {
				return nil, fmt.Errorf("array ended with %v", end)
			}
			return result, nil
		default:
			return nil, fmt.Errorf("unexpected delimiter %q", value)
		}
	case json.Number:
		if !validInteger(string(value)) {
			return nil, fmt.Errorf("non-integer number %q", value)
		}
		if value == "-0" {
			value = "0"
		}
		return value, nil
	case string, bool, nil:
		return value, nil
	default:
		return nil, fmt.Errorf("unsupported JSON token %T", token)
	}
}

func validInteger(value string) bool {
	if value == "0" || value == "-0" {
		return true
	}
	if strings.HasPrefix(value, "-") {
		value = value[1:]
	}
	if value == "" || value[0] < '1' || value[0] > '9' {
		return false
	}
	for _, char := range value[1:] {
		if char < '0' || char > '9' {
			return false
		}
	}
	return true
}

func writeValue(output *bytes.Buffer, value any) error {
	switch value := value.(type) {
	case object:
		keys := make([]string, 0, len(value))
		for key := range value {
			keys = append(keys, key)
		}
		sort.Strings(keys)
		output.WriteByte('{')
		for i, key := range keys {
			if i > 0 {
				output.WriteByte(',')
			}
			encodedKey, err := json.Marshal(key)
			if err != nil {
				return fmt.Errorf("encode object key: %w", err)
			}
			output.Write(encodedKey)
			output.WriteByte(':')
			if err := writeValue(output, value[key]); err != nil {
				return err
			}
		}
		output.WriteByte('}')
	case []any:
		output.WriteByte('[')
		for i, item := range value {
			if i > 0 {
				output.WriteByte(',')
			}
			if err := writeValue(output, item); err != nil {
				return err
			}
		}
		output.WriteByte(']')
	case json.Number:
		output.WriteString(string(value))
	case string:
		encoded, err := json.Marshal(value)
		if err != nil {
			return fmt.Errorf("encode string: %w", err)
		}
		output.Write(encoded)
	case bool:
		if value {
			output.WriteString("true")
		} else {
			output.WriteString("false")
		}
	case nil:
		output.WriteString("null")
	default:
		return fmt.Errorf("unsupported canonical value %T", value)
	}
	return nil
}
