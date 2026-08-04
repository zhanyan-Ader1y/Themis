package canonical_test

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
)

func TestDigestIgnoresObjectKeyOrderButPreservesArrayOrder(t *testing.T) {
	a := json.RawMessage(`{"b":2,"a":1,"items":["x","y"]}`)
	b := json.RawMessage(`{"items":["x","y"],"a":1,"b":2}`)
	c := json.RawMessage(`{"items":["y","x"],"a":1,"b":2}`)
	da, err := canonical.Digest(a)
	if err != nil {
		t.Fatal(err)
	}
	db, err := canonical.Digest(b)
	if err != nil {
		t.Fatal(err)
	}
	dc, err := canonical.Digest(c)
	if err != nil {
		t.Fatal(err)
	}
	if da != db || da == dc {
		t.Fatalf("digests: %s %s %s", da, db, dc)
	}
}

func TestEncodeCanonicalBytes(t *testing.T) {
	input := json.RawMessage(`{"é":4,"😀":5,"z":3,"a":1,"array":[3,2,1],"large":9007199254740993,"negative":-12}`)
	got, err := canonical.Encode(input)
	if err != nil {
		t.Fatal(err)
	}
	want := `{"a":1,"array":[3,2,1],"large":9007199254740993,"negative":-12,"z":3,"é":4,"😀":5}`
	if string(got) != want {
		t.Fatalf("canonical bytes:\n got: %s\nwant: %s", got, want)
	}
}

func TestEncodeCanonicalizesNegativeZeroAndMapValues(t *testing.T) {
	got, err := canonical.Encode(json.RawMessage(`{"negative_zero":-0,"value":9007199254740993}`))
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != `{"negative_zero":0,"value":9007199254740993}` {
		t.Fatalf("canonical integers: %s", got)
	}

	got, err = canonical.Encode(map[string]any{"b": json.Number("2"), "a": "x"})
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != `{"a":"x","b":2}` {
		t.Fatalf("canonical map: %s", got)
	}
}

func TestEncodeHonorsStructJSONTags(t *testing.T) {
	value := struct {
		Z       int    `json:"z"`
		Renamed string `json:"a"`
		Hidden  string `json:"-"`
	}{Z: 2, Renamed: "x", Hidden: "secret"}

	got, err := canonical.Encode(value)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != `{"a":"x","z":2}` {
		t.Fatalf("canonical struct: %s", got)
	}
}

func TestEncodeRejectsInvalidMachineJSON(t *testing.T) {
	tooLarge := append([]byte(`{"value":"`), []byte(strings.Repeat("x", 1<<20))...)
	tooLarge = append(tooLarge, []byte(`"}`)...)

	tests := []struct {
		name  string
		input json.RawMessage
	}{
		{name: "duplicate key", input: json.RawMessage(`{"a":1,"a":2}`)},
		{name: "nested duplicate key", input: json.RawMessage(`{"outer":{"a":1,"a":2}}`)},
		{name: "float", input: json.RawMessage(`{"a":1.5}`)},
		{name: "exponent", input: json.RawMessage(`{"a":1e2}`)},
		{name: "trailing JSON", input: json.RawMessage(`{"a":1}{"b":2}`)},
		{name: "invalid UTF-8", input: json.RawMessage([]byte{'{', '"', 'a', '"', ':', '"', 0xff, '"', '}'})},
		{name: "over machine JSON limit", input: json.RawMessage(tooLarge)},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if _, err := canonical.Encode(test.input); err == nil {
				t.Fatal("expected error")
			}
		})
	}
}

func TestEncodeRejectsFloatInMarshalJSONOutput(t *testing.T) {
	if _, err := canonical.Encode(marshaledFloat{}); err == nil {
		t.Fatal("expected MarshalJSON float error")
	}
}

type marshaledFloat struct{}

func (marshaledFloat) MarshalJSON() ([]byte, error) {
	return []byte(`1.5`), nil
}

func TestEncodeRejectsUnsupportedValueAndNonIntegerNumber(t *testing.T) {
	if _, err := canonical.Encode(make(chan int)); err == nil {
		t.Fatal("expected unsupported value error")
	}
	if _, err := canonical.Encode(json.Number("1.0")); err == nil {
		t.Fatal("expected non-integer number error")
	}
}

func TestDigestFormat(t *testing.T) {
	got, err := canonical.Digest(json.RawMessage(`{"a":1}`))
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != len("sha256:")+64 || !strings.HasPrefix(got, "sha256:") {
		t.Fatalf("digest format: %q", got)
	}
	for _, char := range got[len("sha256:"):] {
		if !(char >= '0' && char <= '9') && !(char >= 'a' && char <= 'f') {
			t.Fatalf("digest is not lowercase hex: %q", got)
		}
	}
}
