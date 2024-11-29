# This code is compatible with Terraform 4.25.0 and versions that are backwards compatible to 4.25.0.
# For information about validating this Terraform code, see https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration

variable "vm-count" {
  type = number
  default = 1
}

variable "vm-user"{
  type = string
  default = "davide"
}

variable "vm-sshkey" {
  type = string
  default = "C:/Users/davide/.ssh/id_rsa.pub"
}

variable "vm-sshkey-private" {
  type = string
  default = "C:/Users/davide/.ssh/id_rsa"
}

variable "vm-zone" {
  type = string
  default = "us-central1-a"
}

variable "vm-type" {
  type = string
  default = "c2-standard-4"
}

variable "vm-slots" {
  type = number
  default = 1
}

variable "vm-np" {
  type = number
  default = 1
}



provider "google" {
  credentials = file("./aca-project-2-74e5e744c429.json")  # Ensure this path is correct, or use gcloud credentials
  project     = "aca-project-2"
  region      = "us-central1"
  zone        = var.vm-zone
}

resource "google_compute_instance" "node" {
  count = var.vm-count
  boot_disk {
    auto_delete = true
    device_name = "node-disk-${count.index}"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240808"
      size  = 25
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = var.vm-type

   metadata = {
    ssh-keys = "${var.vm-user}:${file(var.vm-sshkey)}"
  }

  name = "node-${count.index}"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/aca-project-2/regions/us-central1/subnetworks/default"
  }

  scheduling {
    automatic_restart   = false
    on_host_maintenance = "TERMINATE"
    preemptible         = true
    provisioning_model  = "SPOT"
  }

  service_account {
    email  = "185963958769-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  zone = var.vm-zone

connection {
      type = "ssh"
      user = var.vm-user
      private_key = file(var.vm-sshkey-private)
      host = self.network_interface.0.access_config.0.nat_ip
    }

  provisioner "file" {
    content     = templatefile(count.index == 0 ? "./init.sh" : "./init-slave.sh", 
      {
        ssh_key = file("./master/id_rsa.pub")
      })
    destination = "/tmp/node_setup.sh"
    

    
  }


  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/node_setup.sh",
      "/tmp/node_setup.sh",
    ]
  }
}

resource "null_resource" "execute_on_master" {
  depends_on = [google_compute_instance.node]

  triggers = {
    instance_ids = google_compute_instance.node[0].id
  }

  connection {
    type        = "ssh"
    user        = var.vm-user
    private_key = file(var.vm-sshkey-private)
    host        = google_compute_instance.node[0].network_interface[0].access_config[0].nat_ip
  }


  provisioner "file" {
    source      = "./master/id_rsa"
    destination = "/home/${var.vm-user}/.ssh/id_rsa"
  }

  
  provisioner "file" {
    source      = "./master/id_rsa.pub"
    destination = "/home/${var.vm-user}/.ssh/id_rsa.pub"
  }

  provisioner "remote-exec" {
    inline = concat(
      ["sudo chmod 600 /home/${var.vm-user}/.ssh/id_rsa"],
      [for i in range(1, length(google_compute_instance.node)): "sudo ssh-keyscan -H node-${i} >> /home/${var.vm-user}/.ssh/known_hosts"],
      [for i in range(0, length(google_compute_instance.node)): "sudo echo 'node-${i} slots=${var.vm-slots}' >> /home/${var.vm-user}/data/hostfile"],
      ["cd /home/${var.vm-user}/data && mpirun -np ${var.vm-np} --hostfile hostfile ./cray-demo -f ../aca-project/src-cray-demo/assets/hdr.json -o output/"])
  }
}

resource "null_resource" "download_render" {
  depends_on = [null_resource.execute_on_master]

  triggers = {
    always_run = "${timestamp()}"  # This will cause it to run on every apply
  }

  provisioner "local-exec" {
  command = "scp -o UserKnownHostsFile=NUL -o StrictHostKeyChecking=no -i ${var.vm-sshkey-private} ${var.vm-user}@${google_compute_instance.node[0].network_interface[0].access_config[0].nat_ip}:/home/${var.vm-user}/data/output/output_0000.png ."
}

}