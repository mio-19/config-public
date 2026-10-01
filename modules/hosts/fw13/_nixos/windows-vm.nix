{
  config,
  lib,
  pkgs,
  ...
}:

{
  # =======================================================================
  # High-Performance Windows VM Configuration (Intel Lunar Lake / FW13)
  # Hypervisor: QEMU/KVM
  # GPU: Intel Xe3 SR-IOV
  # Display/Audio: Looking Glass & Scream
  # =======================================================================

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
    };
  };

  # Host packages required for the setup
  environment.systemPackages = with pkgs; [
    virt-manager
    looking-glass-client
    scream # Audio receiver for PipeWire
  ];

  # Enable IOMMU for PCI Passthrough
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    # "xe.force_probe=*" # Uncomment if required for Lunar Lake Xe3 on your current kernel
  ];

  boot.kernelModules = [
    "kvm-intel"
    "vfio_pci"
    "vfio_iommu_type1"
    "vfio_virqfd"
  ];

  # Looking Glass KVMFR module setup
  boot.extraModulePackages = with config.boot.kernelPackages; [
    looking-glass-module
  ];

  # Allocate 64MB shared memory for Looking Glass (adjust if higher than 1080p/1440p is needed)
  boot.extraModprobeConfig = ''
    options kvmfr static_size_mb=64
  '';

  services.udev.extraRules = ''
    # Set permissions for the Looking Glass shared memory device so the libvirt/kvm group can read it
    SUBSYSTEM=="kvmfr", OWNER="root", GROUP="kvm", MODE="0660"

    # -----------------------------------------------------------------------------------
    # Intel SR-IOV Virtual Function (VF) Auto-Creation
    # -----------------------------------------------------------------------------------
    # This rule automatically spawns 1 VF for the Intel Arc GPU.
    # IMPORTANT: Verify your GPU's PCI vendor/class or specific device ID before uncommenting.
    # 
    # ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{class}=="0x030000", ATTR{sriov_numvfs}="1"
  '';

  # Pre-create the Scream shared memory file with permissions so the user audio service can read it
  systemd.tmpfiles.rules = [
    "f /dev/shm/scream-ivshmem 0666 root kvm -"
  ];

  # Ensure the Scream audio receiver runs in the background for your user session
  systemd.user.services.scream-receiver = {
    description = "Scream IVSHMEM Audio Receiver";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.scream}/bin/scream -m /dev/shm/scream-ivshmem";
      Restart = "always";
      RestartSec = "5";
    };
  };
}
