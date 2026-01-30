# Security Policy - Enterprise AI Grid
package terraform.validation

# Deny unencrypted S3 buckets
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.server_side_encryption_configuration
    msg := sprintf("S3 bucket %v must have encryption enabled", [resource.address])
}

# Require tags
deny[msg] {
    resource := input.resource_changes[_]
    not resource.change.after.tags.Environment
    msg := sprintf("Resource %v missing required tag: Environment", [resource.address])
}

# Limit instance sizes
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    prohibited := ["m5.24xlarge", "c5.24xlarge"]
    resource.change.after.instance_type == prohibited[_]
    msg := sprintf("Instance type %v exceeds approved sizes", [resource.change.after.instance_type])
}
