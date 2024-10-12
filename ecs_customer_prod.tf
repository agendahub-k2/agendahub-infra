# Criar o VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc"
  }
}

# Criar uma Sub-rede pública
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

# Criar o Grupo de Segurança
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_security_group"
  }
}

# Criar um Grupo de Logs do CloudWatch
resource "aws_cloudwatch_log_group" "log-customer" {
  name              = "log-customer"
  retention_in_days = 7  # Ajuste a retenção conforme necessário
}

# Criar a Definição de Tarefa
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"   # 1 vCPU
  memory                   = "2048"   # 2 GB de memória
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn  # Adicione a role de execução

  container_definitions = jsonencode([
    {
      name      = "my-container"
      image     = "825765415863.dkr.ecr.sa-east-1.amazonaws.com/agenda:latest"
      memory    = 2048
      cpu       = 1024
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        },
      ]
      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "qa"
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.log-customer.name
          "awslogs-region"       = "sa-east-1"  # Altere para sua região
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Criar o Serviço ECS
resource "aws_ecs_service" "my_service" {
  name            = "ecs-service-customer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

# Criar o Cluster ECS
resource "aws_ecs_cluster" "main" {
  name = "app-agendahub"
}

# Criar a Role de Execução do ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

# Anexar a Política de Logs à Role
resource "aws_iam_role_policy_attachment" "ecs_execution_logs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution_role.name
}
