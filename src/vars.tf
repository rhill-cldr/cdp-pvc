data "external" "env" {
    program = ["${path.module}/info.sh"]
}

variable "equinix_metal_auth_token" {
  type        = string
  description = "Equinix Metal auth token."
  default = data.external.env.result["EQUINIX_METAL_AUTH_TOKEN"]
}
