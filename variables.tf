variable "function_version" {
  description = "Release of lambda-budget-ledger-add to deploy, without the leading v, for example 0.1.0. `task download` must have fetched it first."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.function_version))
    error_message = "function_version must look like 0.1.0, without a leading v."
  }
}
