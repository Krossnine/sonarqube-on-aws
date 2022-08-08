output "alb_hostname" {
  description = "Ths URL of the sonarqube load balancer"
  value       = module.sonar_alb.lb_dns_name
}
