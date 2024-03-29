packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/amazon"
    }
    googlecompute = {
      version = ">= 1.1.4"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "version" {
  type    = string
  default = "1.0.1"
}

data "amazon-ami" "ubuntu-focal-east" {
  region = "us-east-2"
  filters = {
    name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "basic-example-east" {
  region         = "us-east-2"
  source_ami     = data.amazon-ami.ubuntu-focal-east.id
  instance_type  = "t2.small"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "packer_AWS_{{timestamp}}_v${var.version}"
}

data "amazon-ami" "ubuntu-focal-west" {
  region = "us-west-1"
  filters = {
    name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "basic-example-west" {
  region         = "us-west-1"
  source_ami     = data.amazon-ami.ubuntu-focal-west.id
  instance_type  = "t2.small"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "packer_AWS_{{timestamp}}_v${var.version}"
}

source "googlecompute" "basic-example-gcp" {
  project_id          = "hc-1dd9ddc1f2704ff99c6b6415550"
  zone                = "us-central1-f"
  source_image_family = "ubuntu-2004-lts"
  image_description   = "built with packer"
  ssh_username        = "ubuntu"
  image_name          = "packer-gcp-{{timestamp}}-v${replace(var.version, ".", "-")}"
}

build {
  hcp_packer_registry {
    bucket_name = "learn-packer-ubuntu"
    description = <<EOT
MEOW WORLD.
    EOT
    bucket_labels = {
      "owner"          = "platform-team"
      "os"             = "Ubuntu",
      "ubuntu-version" = "Focal 20.04",
    }

    build_labels = {
      "build-time"   = timestamp()
      "build-source" = basename(path.cwd)
    }
  }
  sources = [
    "source.amazon-ebs.basic-example-east",
    "source.amazon-ebs.basic-example-west",
    "source.googlecompute.basic-example-gcp"
  ]
}
