# Application Auto Scaling
resource "aws_appautoscaling_target" "weather_app" {
  max_capacity       = var.max_instances
  min_capacity       = var.min_instances
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.weather_app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale up based on CPU
resource "aws_appautoscaling_policy" "weather_app_cpu" {
  name               = "${var.project_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.weather_app.resource_id
  scalable_dimension = aws_appautoscaling_target.weather_app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.weather_app.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Scale up based on memory
resource "aws_appautoscaling_policy" "weather_app_memory" {
  name               = "${var.project_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.weather_app.resource_id
  scalable_dimension = aws_appautoscaling_target.weather_app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.weather_app.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
