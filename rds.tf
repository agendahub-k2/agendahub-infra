provider "aws" {
  region = "sa-east-1"
}

resource "aws_db_instance" "customer_database" {
  identifier              = "customer-database"
  engine                 = "mysql"
  engine_version         = "8.0"  # Ou outra versão que preferir
  instance_class         = "db.t3.micro"  # Tipo de instância
  allocated_storage       = 20  # Em GB
  storage_type           = "gp2"  # Tipo de armazenamento
  username               = "agendahub_customer_admin"  # Nome de usuário do banco
  password               = "italok2k2"  # Senha do banco (use uma senha forte)
  db_name                = "customer"  # Nome do banco de dados
  publicly_accessible     = true  # Altere conforme necessário (público ou privado)
  skip_final_snapshot    = true  # Para desenvolvimento, altere para false em produção

  tags = {
    Name = "customer"
  }

  vpc_security_group_ids = [aws_security_group.my_db_sg.id]  # Associar ao grupo de segurança
}

resource "aws_security_group" "my_db_sg" {
  name        = "my-db-sg"
  description = "Allow access to MySQL"
  
  ingress {
    from_port   = 3306  # Porta do MySQL
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permitir acesso de qualquer lugar (modifique para restringir)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Permitir saída para qualquer lugar
  }
}
