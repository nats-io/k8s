package test

import "strings"

// https://github.com/Masterminds/sprig/blob/master/strings.go
func indent(spaces int, v string) string {
	pad := strings.Repeat(" ", spaces)
	return pad + strings.Replace(v, "\n", "\n"+pad, -1)
}
