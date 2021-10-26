variable "prefix" {
  type        = string
  default     = "fasmt-04-3-sisayev"
  description = "prefix to resources names"
}

variable "lambda_sqs_role" {
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  description = "role sqs for lambda"
}

variable "lambda_subnets" {
    type = list(string)
    default = ["subnet-0c98e1819f7381e46", "subnet-04d9ba157b61c1802"]
    description = "subnets for lambda"
}

variable "lambda_sg" {
    type = list(string)
    default = ["sg-0f06ff268ce11ca74","sg-08f0649712e4e4fd5"]
    description = "sg for lambda"
}