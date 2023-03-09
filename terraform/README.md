<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.32.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_platform_delivery_validator"></a> [platform\_delivery\_validator](#module\_platform\_delivery\_validator) | ../tf-synthetics-canary/terraform | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_path_synthetics_canary_code"></a> [bucket\_path\_synthetics\_canary\_code](#input\_bucket\_path\_synthetics\_canary\_code) | The bucket path to the deployment package | `string` | n/a | yes |
| <a name="input_bucket_synthetics_canary_code"></a> [bucket\_synthetics\_canary\_code](#input\_bucket\_synthetics\_canary\_code) | The bucket to store the canary code | `string` | n/a | yes |
| <a name="input_git_branch"></a> [git\_branch](#input\_git\_branch) | The name of the git branch for deployment | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_arn"></a> [lambda\_arn](#output\_lambda\_arn) | n/a |
<!-- END_TF_DOCS -->