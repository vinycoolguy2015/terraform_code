variable "vpc_cidr" {}
variable "private_subnet" {}
variable "public_subnet" {}
variable "docker_container_port" {
  default = 3000
}
variable "memory" {
  default = 512
}
variable "desired_task_number" {
  default = 1
}
variable "cpu" {
  default = 256
}
variable "build_timeout" {
  default = 60
}
variable "queued_timeout" {
  default = 60
}
