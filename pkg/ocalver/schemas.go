package ocalver

import (
	"fmt"

	"github.com/go-git/go-git/v5/plumbing"
)

// Config ..
type Config struct {
	Pre            string
	RepositoryPath string
}

// TagInfo ..
type TagInfo struct {
	Year      int
	YearDay   int
	Iteration int
	PreInfo   *PreInfo
	Hash      plumbing.Hash
}

// PreInfo ..
type PreInfo struct {
	Name       string
	Iteration  int
	CommitHash string
}

// String ..
func (t *TagInfo) String() string {
	if t.PreInfo != nil {
		return fmt.Sprintf("%d.%d.%d-%s.%d+%s", t.Year, t.YearDay, t.Iteration, t.PreInfo.Name, t.PreInfo.Iteration, t.PreInfo.CommitHash)
	}
	return fmt.Sprintf("%d.%d.%d", t.Year, t.YearDay, t.Iteration)
}
