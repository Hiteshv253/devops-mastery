# Terraform Resource Import Guide (MNC Patterns)

In enterprise environments, you will often find resources that were created manually (via the AWS/Azure Console) or through temporary scripts. To bring them under Terraform control, you must **import** them.

This tutorial covers the two methods of importing resources:
1. **The Modern Declarative Way (Terraform 1.5+)** - *Recommended for new projects*
2. **The Traditional CLI Way (`terraform import`)** - *Common in legacy codebases*

---

## Method 1: The Modern Declarative `import` Block (Terraform 1.5+)

Starting from Terraform 1.5, you can use the `import` block. This is highly preferred in MNCs because it is **version-controlled** and allows Terraform to **generate the resource code automatically** for you.

### Step-by-Step Scenario
Imagine someone manually created an S3 bucket in AWS called `legacy-manual-bucket-hitesh`.

### Step 1: Add the `import` block to your code
Create a file called `imports.tf` in your environment directory:

```hcl
import {
  to = aws_s3_bucket.imported_bucket
  id = "legacy-manual-bucket-hitesh"
}
```

### Step 2: Generate the Resource Configuration
Instead of writing the resource block by hand, run Terraform's generator command:
```bash
terraform plan -generate-config-out=generated_resources.tf
```

Terraform will:
1. Connect to AWS.
2. Read the properties of `legacy-manual-bucket-hitesh`.
3. Create a new file called `generated_resources.tf` containing the exact code for `aws_s3_bucket.imported_bucket`.

### Step 3: Apply to Update the State
Review the generated file, make adjustments, and run:
```bash
terraform apply
```
This updates the local/remote state file without destroying or recreating the bucket.

---

## Method 2: The Traditional CLI Way (`terraform import`)

If you are working on older Terraform versions (< 1.5), you must write the empty resource shell first and run a CLI command.

### Step 1: Write the resource block manually
Write the empty code shell in your code (e.g., `main.tf`):
```hcl
resource "aws_s3_bucket" "imported_bucket" {
  # Leave attributes empty or guess them; you will fix them after importing.
}
```

### Step 2: Execute the Import Command
Run the `terraform import` command, specifying the resource address and the actual Cloud resource ID:
```bash
terraform import aws_s3_bucket.imported_bucket legacy-manual-bucket-hitesh
```

### Step 3: Align Configuration with State
After running the command, your state has the real data, but your `main.tf` is empty. If you run `terraform plan`, Terraform will try to delete or modify settings. You must manually copy attributes from the state file (`terraform.tfstate`) into your resource block until `terraform plan` reports **"No changes. Your infrastructure matches the configuration."**

---

## Best Practices in MNCs for Importing

1. **State Backup First**: Always backup your remote state bucket or run a local backup before running any import operations.
2. **Use `-dry-run` or `plan`**: Check changes thoroughly. Make sure the import doesn't accidentally trigger a recreation (recreate/replace) of production resources.
3. **Locking**: Ensure state locking is enabled (via DynamoDB) so no other pipeline or developer runs a plan while you are executing imports.
