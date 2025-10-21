package test

import (
	"os/exec"
	"strings"
	"testing"
)

func TestTerraformPlan(t *testing.T) {
	cmd := exec.Command("terraform", "plan", "-out=tfplan")
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Error running terraform plan: %s\nOutput: %s", err, output)
	}

	if !strings.Contains(string(output), "No changes. Infrastructure is up-to-date.") {
		t.Fatal("Terraform plan indicates changes, which is unexpected.")
	}
}