package ocalver

import (
	"fmt"
	"path/filepath"
	"regexp"
	"strconv"
	"time"

	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing"
	"github.com/go-git/go-git/v5/plumbing/object"
)

const (
	tagRegexp    string = `^(\d+).(\d+).(\d+)$`
	tagPreRegexp string = `^(\d+).(\d+).(\d+)-%s.(\d+)+[a-f0-9]{7,10}$`
)

// Generate a new version based on the provided repo config/params
func Generate(cfg Config) (string, error) {
	r, err := git.PlainOpen(filepath.Dir(cfg.RepositoryPath))
	if err != nil {
		return "", err
	}

	tags, err := r.Tags()
	if err != nil {
		return "", err
	}

	var mostRecentTagRef *plumbing.Reference
	re := getRegexp("")
	_ = tags.ForEach(func(ref *plumbing.Reference) error {
		if re.Match([]byte(ref.Name().Short())) {
			mostRecentTagRef = ref
		}
		return nil
	})

	tagInfo := TagInfo{}
	if mostRecentTagRef != nil {
		tagInfo, err = extractTagInfo(mostRecentTagRef, "")
		if err != nil {
			return "", err
		}
	}

	nextTagInfo := nextTagInfo(tagInfo)
	if len(cfg.Pre) > 0 {
		if err = nextTagInfo.GetPreInfo(r, tagInfo, cfg.Pre); err != nil {
			return "", err
		}
	}

	return nextTagInfo.String(), nil
}

func getRegexp(pre string) *regexp.Regexp {
	if len(pre) > 0 {
		return regexp.MustCompile(fmt.Sprintf(tagPreRegexp, pre))
	}
	return regexp.MustCompile(tagRegexp)
}

func extractTagInfo(ref *plumbing.Reference, pre string) (t TagInfo, err error) {
	t.Hash = ref.Hash()

	re := getRegexp(pre)
	d := re.FindStringSubmatch(ref.Name().Short())
	expectedLength := 4
	if len(pre) > 0 {
		expectedLength = 6
	}

	if len(d) != expectedLength {
		err = fmt.Errorf("invalid tag format %v", d)
		return
	}

	if len(pre) > 0 {
		t.PreInfo = &PreInfo{}
		t.PreInfo.Name = pre
		if t.PreInfo.Iteration, err = strconv.Atoi(d[4]); err != nil {
			return
		}
		t.PreInfo.CommitHash = d[5]
	}

	if t.Year, err = strconv.Atoi(d[1]); err != nil {
		return
	}

	if t.YearDay, err = strconv.Atoi(d[2]); err != nil {
		return
	}

	t.Iteration, err = strconv.Atoi(d[3])
	return
}

func nextTagInfo(ori TagInfo) (new TagInfo) {
	new.Year = time.Now().Year() - 2000
	new.YearDay = time.Now().YearDay()
	if TagsShareDate(ori, new) {
		new.Iteration = ori.Iteration + 1
	}

	return
}

// TagsShareDate returns whether 2 TagInfo objects have the same date
func TagsShareDate(a, b TagInfo) bool {
	return a.Year == b.Year && a.YearDay == b.YearDay
}

// GetPreInfo ..
func (t *TagInfo) GetPreInfo(r *git.Repository, ori TagInfo, pre string) error {
	t.PreInfo = &PreInfo{
		Name:      pre,
		Iteration: 1,
	}

	h, err := r.Head()
	if err != nil {
		return err
	}

	headCommit, err := r.CommitObject(h.Hash())
	if err != nil {
		return err
	}
	t.PreInfo.CommitHash = headCommit.Hash.String()[:8]

	if TagsShareDate(*t, ori) && ori.Hash != (plumbing.Hash{}) {
		tagCommit, err := r.CommitObject(ori.Hash)
		if err != nil {
			return err
		}

		isAncestor, err := tagCommit.IsAncestor(headCommit)
		if err != nil {
			return err
		}

		if isAncestor {
			commits, err := tagCommit.MergeBase(headCommit)
			if err != nil {
				return nil
			}

			t.PreInfo.Iteration = len(commits)
		}
	} else {
		since := time.Date(time.Now().UTC().Year(), time.Now().UTC().Month(), time.Now().UTC().Day(), 0, 0, 0, 0, time.UTC)
		commits, err := r.Log(&git.LogOptions{Since: &since})
		if err != nil {
			return err
		}

		var count int
		_ = commits.ForEach(func(_ *object.Commit) error {
			count++
			return nil
		})

		if count > 0 {
			t.PreInfo.Iteration = count
		}
	}

	return nil
}
