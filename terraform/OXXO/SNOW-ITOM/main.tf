# ============================================================
# OCI Terraform - OXOCI-VM-APP-SNOWITON-PRD
# ServiceNow ITOM MID Server
# CHG: CHG0140789
# Date: 02-12-2026
# ============================================================

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

# ============================================================
# PROVIDER
# ============================================================
provider "oci" {
  region = "mx-monterrey-1"
}

# ============================================================
# LOCALS
# ============================================================
locals {
  availability_domain = "HSqW:MX-MONTERREY-1-AD-1"
  compartment_id      = "ocid1.compartment.oc1..aaaaaaaawond7xtn3whlzg2n3k24q7jfe6iyt5mmjspnr73wq4htxqkprgta"
  subnet_id           = "ocid1.subnet.oc1.mx-monterrey-1.aaaaaaaau5kkq4x6wku2bgpejmmsui5dsreeh72zqhbocwy2jr2ppjdj3ruq"
  image_id            = "ocid1.image.oc1.mx-monterrey-1.aaaaaaaapusepjywfsvwzwbgyxnxokn5cfzrebny2o542vhzqwnfptxcfyba"
  instance_name       = "OXOCI-VM-APP-SNOWITON-PRD"
  block_volume_name   = "OXOCI-BLKVL-APP-SNOWITON-PROD-DATA"
}

# ============================================================
# BACKUP POLICY - GOLD
# ============================================================
data "oci_core_volume_backup_policies" "predefined" {}

locals {
  gold_backup_policy_id = one([
    for policy in data.oci_core_volume_backup_policies.predefined.volume_backup_policies :
    policy.id if lower(policy.display_name) == "gold"
  ])
}

# ============================================================
# CLOUD-INIT SCRIPT
# ============================================================
data "cloudinit_config" "windows_init" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/userdata.ps1")
  }
}

# ============================================================
# COMPUTE INSTANCE
# ============================================================
resource "oci_core_instance" "snow_itom_instance" {
  availability_domain = local.availability_domain
  compartment_id      = local.compartment_id
  display_name        = local.instance_name
  shape               = "VM.Standard.E5.Flex"

  shape_config {
    ocpus         = 8
    memory_in_gbs = 8
  }

  source_details {
    source_type             = "image"
    source_id               = local.image_id
    boot_volume_size_in_gbs = 128
  }

  create_vnic_details {
    subnet_id        = local.subnet_id
    display_name     = "${local.instance_name}-VNIC"
    assign_public_ip = false
    hostname_label   = null
  }

  metadata = {
    user_data = data.cloudinit_config.windows_init.rendered
  }

  # ============================================================
  # DEFINED TAGS
  # ============================================================
  defined_tags = {
    # Standard-Tags - Business
    "Standard-Tags.BusinessUnit"          = "FEMSA Servicios"
    "Standard-Tags.Area"                  = "Centro Operaciones"
    "Standard-Tags.ProjectName"           = "Service Now ITOM"
    "Standard-Tags.Environment"           = "PRD"
    "Standard-Tags.Requester"             = "Morales Rodriguez Alicia Anahi"
    "Standard-Tags.Approver"              = "Briones Garza Alejandro"
    "Standard-Tags.Owner"                 = "Morales Rodriguez Alicia Anahi"
    "Standard-Tags.OwnerTeam"             = "Centro Operaciones"
    "Standard-Tags.OwnerRole"             = "COORDINADOR GESTION ACTIVOS"
    "Standard-Tags.CloudArchitect"        = "Juan Carlos Romero"

    # Standard-Tags - Cost Management
    "Standard-Tags.CostCenter"            = "43zgn"
    "Standard-Tags.SI"                    = ""
    "Standard-Tags.PurchaseType"          = "on-demand"

    # Standard-Tags - Operational
    "Standard-Tags.Hostname"              = "OXOCI-VM-APP-SNOWITON-PRD"
    "Standard-Tags.Description"           = "SNow ITOM Scanner"
    "Standard-Tags.Role"                  = "SNow ITOM MID Server"
    "Standard-Tags.Application"           = "SNow ITOM MID Server"
    "Standard-Tags.Criticality"           = "low"
    "Standard-Tags.OSManagedBy"           = "Kyndryl"
    "Standard-Tags.Domain"                = "proximidad.com"
    "Standard-Tags.AccessByVaultStatus"   = "accessible"
    "Standard-Tags.AccessByBastionStatus" = "accessible"
    "Standard-Tags.ServiceHours"          = "always-on"
    "Standard-Tags.ComplianceRequirement" = ""
    "Standard-Tags.CloudAgentStatus"      = "ok"
    "Standard-Tags.LifeCycleStatus"       = "deployment"
    "Standard-Tags.AccessLevel"           = "private"
    "Standard-Tags.TerminateByDate"       = ""
    "Standard-Tags.CreatedBy"             = "IaC (Terraform)"
    "Standard-Tags.CreatedByTeam"         = "Kyndryl"
    "Standard-Tags.CreationDate"          = "02-12-2026"
    "Standard-Tags.ChangeOrder"           = "CHG0140789"

    # Standard-Tags - GRC
    "Standard-Tags.XDR"                   = ""
    "Standard-Tags.VulnerabilityScanner"  = ""
    "Standard-Tags.EndpointManager"       = ""
    "Standard-Tags.CMDBStatus"            = "not-discovered"
    "Standard-Tags.LastPatchedOn"         = ""
    "Standard-Tags.DataClassification"    = "confidential"
    "Standard-Tags.DataResidency"         = "Mexico"
    "Standard-Tags.BackupPolicy"          = "standard"

    # J2C - Spanish Tags
    "J2C.NombreDelProyecto"              = "SNow ITOM MID Server"
    "J2C.ClasificacionDeDatos"           = "Confidencial"
    "J2C.NombreDelPropietario"           = "Morales Rodriguez Alicia Anahi"
    "J2C.NombreDeImplementador"          = "Jesucristo Thopson"
    "J2C.NombreDelSolicitante"           = "Juan Carlos Romero"
    "J2C.BusDeNegocio"                   = "Digital"
    "J2C.PlataformaTecnologica"          = "Infraestructura"
    "J2C.CentroDeGastos(CR)"             = "43zgn"
    "J2C.SolicitudDeInversion(SI)"       = ""
    "J2C.Uso"                            = "SNow ITOM MID Server"
    "J2C.Geografia"                      = "México"
    "J2C.Ambiente"                       = "PRD"
    "J2C.FechaDeImplementacion"          = "02-12-2026"
    "J2C.AreasJ2C"                       = "Cloud Operation"
  }
}

# ============================================================
# BOOT VOLUME BACKUP POLICY ASSIGNMENT
# ============================================================
resource "oci_core_volume_backup_policy_assignment" "boot_volume_backup" {
  asset_id  = oci_core_instance.snow_itom_instance.boot_volume_id
  policy_id = local.gold_backup_policy_id
}

# ============================================================
# BLOCK VOLUME
# ============================================================
resource "oci_core_volume" "data_volume" {
  availability_domain = local.availability_domain
  compartment_id      = local.compartment_id
  display_name        = local.block_volume_name
  size_in_gbs         = 128

  defined_tags = {
    "Standard-Tags.BusinessUnit"       = "FEMSA Servicios"
    "Standard-Tags.Environment"        = "PRD"
    "Standard-Tags.ProjectName"        = "Service Now ITOM"
    "Standard-Tags.CreatedBy"          = "IaC (Terraform)"
    "Standard-Tags.CreatedByTeam"      = "Kyndryl"
    "Standard-Tags.CreationDate"       = "02-12-2026"
    "Standard-Tags.ChangeOrder"        = "CHG0140789"
    "Standard-Tags.DataClassification" = "confidential"
    "Standard-Tags.AccessLevel"        = "private"
  }
}

# ============================================================
# BLOCK VOLUME ATTACHMENT
# ============================================================
resource "oci_core_volume_attachment" "data_volume_attachment" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.snow_itom_instance.id
  volume_id       = oci_core_volume.data_volume.id
  display_name    = "${local.block_volume_name}-ATTACHMENT"
  is_read_only    = false
  is_shareable    = false
}

# ============================================================
# BLOCK VOLUME BACKUP POLICY ASSIGNMENT
# ============================================================
resource "oci_core_volume_backup_policy_assignment" "data_volume_backup" {
  asset_id  = oci_core_volume.data_volume.id
  policy_id = local.gold_backup_policy_id
}

# ============================================================
# OUTPUTS
# ============================================================
output "instance_id" {
  value = oci_core_instance.snow_itom_instance.id
}

output "instance_private_ip" {
  value = oci_core_instance.snow_itom_instance.private_ip
}

output "boot_volume_id" {
  value = oci_core_instance.snow_itom_instance.boot_volume_id
}

output "data_volume_id" {
  value = oci_core_volume.data_volume.id
}
