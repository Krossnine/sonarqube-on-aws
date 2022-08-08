variable "name_prefix" {
  type        = string
  description = "Name prefix for resources on AWS"
  default     = "sonarqube"
}

variable "region" {
  description = "The region where sonarqube must be deployed"
  default     = "eu-west-1"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Default resource tags"
}

variable "db_engine_version" {
  type        = string
  default     = "13.4"
  description = "DB engine version"
}

variable "db_port" {
  type        = number
  default     = 5432
  description = "DB port"
}

variable "db_instance_size" {
  type        = string
  default     = "db.t3.medium"
  description = "DB instance size"
}

variable "db_name" {
  type        = string
  default     = "sonar"
  description = "Default DB name"
}

variable "db_username" {
  type        = string
  default     = "sonar"
  description = "Default DB username"
}

variable "db_password" {
  type        = string
  default     = ""
  description = "DB password"
}

variable "sonar_image" {
  description = "Sonarqube image"
  type        = string
  default     = "sonarqube:9.5.0-community"
}

variable "sonar_port" {
  type        = number
  default     = 9000
  description = "Default sonar port"
}

variable "sonar_task_cpu" {
  type        = number
  default     = 1024
  description = "Task definition CPU"
}

variable "sonar_task_memory" {
  type        = number
  default     = 2048
  description = "Task definition Memory"
}