# efs security group

resource "aws_security_group" "efs" {
  name        = "efs.${local.lower_name}"
  description = "Security group for efs in the cluster"

  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
      "Name", "efs.${local.lower_name}",
      "kubernetes.io/cluster/${local.lower_name}", "owned",
      "SG_Groups", "ALERTNOW-PRD OKC3-eks-efs",
    )
  }"
}

resource "aws_security_group_rule" "efs-ingress-worker" {
  description              = "Allow worker to communicate with each other"
  security_group_id        = "${aws_security_group.efs.id}"
  source_security_group_id = "${aws_security_group.worker.id}"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "-1"
  type                     = "ingress"
}
