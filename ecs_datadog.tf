resource "aws_ecs_task_definition" "datadog" {
  family        = "${var.env}-${var.identifier}-datadog-task"
  task_role_arn = "${aws_iam_role.ecs-datadog-role.arn}"

  container_definitions = <<EOF
[
  {
    "name": "${var.env}-${var.identifier}",
    "image": "datadog/agent:latest",
    "cpu": 10,
    "memory": 256,
    "portMappings": [{
            "containerPort": 8126,
            "protocol": "tcp",
            "hostPort": 8126
    }],
    "environment": [{
      "name" : "DD_API_KEY",
      "value" : "${var.datadog-api-key}"
    },
    {
      "name" : "DD_APM_ENABLED",
      "value" : "${var.datadog-apm}"
    },
    {
      "name" : "DD_APM_NON_LOCAL_TRAFFIC",
      "value" : "${var.dd-apm-non-local-traffic}"
    }
    ],
    "command": [
      "bash",
      "-c",
      "${var.datadog-extra-config}"
    ],
    "mountPoints": [{
      "sourceVolume": "docker-sock",
      "containerPath": "/var/run/docker.sock",
      "readOnly": true
    },{
      "sourceVolume": "proc",
      "containerPath": "/host/proc",
      "readOnly": true
    },{
      "sourceVolume": "cgroup",
      "containerPath": "/host/sys/fs/cgroup",
      "readOnly": true
    }]
  }
]
EOF

  volume {
    name      = "docker-sock"
    host_path = "/var/run/docker.sock"
  }

  volume {
    name      = "proc"
    host_path = "/proc/"
  }

  volume {
    name      = "cgroup"
    host_path = "/sys/fs/cgroup/"
  }
}

resource "aws_ecs_service" "datadog" {
  name            = "${var.env}-${var.identifier}-datadog-ecs-service"
  cluster         = "${var.ecs-cluster-id}"
  task_definition = "${aws_ecs_task_definition.datadog.arn}"

  scheduling_strategy = "${var.scheduling-strategy}"  #To be run as REPLICA in test environment only  
}

