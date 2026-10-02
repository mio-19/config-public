{
  config,
  lib,
  pkgs,
  ...
}:

let
  cpuPinning = true;
in
lib.optionalAttrs (config.microarch == "intel-ultra-xe") {
  # =======================================================================
  # High-Performance Windows VM Configuration (Intel Lunar Lake / FW13)
  # Hypervisor: QEMU/KVM
  # GPU: Intel Xe3 SR-IOV
  # Display/Audio: Looking Glass & Scream
  # =======================================================================
  #
  # MANUALLY CREATE THE SPARSE 1TB ZVOL FIRST:
  # sudo zfs create -s -V 1TB -o volblocksize=64K razer/nixos/safe/encrypted/user/win-vm
  #
  # Note: The `-s` flag enables Thin Provisioning (Sparse). The XML below passes
  # TRIM/UNMAP commands to ZFS via `virtio-scsi` and `discard='unmap'`, returning
  # freed space automatically back to your `razer` pool!
  # =======================================================================

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    virt-manager
    looking-glass-client
    scream # Audio receiver for PipeWire
  ];

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

  boot.extraModulePackages = with config.boot.kernelPackages; [
    kvmfr
  ];

  boot.extraModprobeConfig = ''
    options kvmfr static_size_mb=64
  '';

  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", OWNER="root", GROUP="kvm", MODE="0660"

    # Automatically create 1 Virtual Function (vGPU) for the Intel GPU at boot
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{class}=="0x030000", ATTR{sriov_numvfs}="1"
  '';

  systemd.tmpfiles.rules = [
    "f /dev/shm/scream-ivshmem 0666 root kvm -"
  ];

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

  # =======================================================================
  # Fully Declarative Libvirt XML Injection
  # =======================================================================
  systemd.services.define-windows-vm = {
    description = "Declaratively define the Windows VM in Libvirt";
    wantedBy = [ "multi-user.target" ];
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.libvirt}/bin/virsh define ${pkgs.writeText "windows-vm.xml" ''
        <domain type='kvm'>
          <name>Windows11</name>
          <memory unit='GiB'>16</memory>
          <currentMemory unit='GiB'>16</currentMemory>
          
          ${
            if cpuPinning then
              ''
                <vcpu placement='static'>4</vcpu>
                <cputune>
                  <vcpupin vcpu="0" cpuset="0"/>
                  <vcpupin vcpu="1" cpuset="1"/>
                  <vcpupin vcpu="2" cpuset="2"/>
                  <vcpupin vcpu="3" cpuset="3"/>
                  <!-- Offload QEMU emulator overhead to Skymont E-cores -->
                  <emulatorpin cpuset="4-7"/>
                </cputune>
              ''
            else
              ''
                <vcpu>4</vcpu>
              ''
          }
          
          <os>
            <type arch='x86_64' machine='q35'>hvm</type>
            <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
          </os>
          
          <features>
            <acpi/>
            <apic/>
            <hyperv mode='custom'>
              <relaxed state='on'/>
              <vapic state='on'/>
              <spinlocks state='on' retries='8191'/>
              <vpindex state='on'/>
              <runtime state='on'/>
              <synic state='on'/>
              <stimer state='on'>
                <direct state='on'/>
              </stimer>
              <reset state='on'/>
              <vendor_id state='on' value='1234567890ab'/>
              <frequencies state='on'/>
              <tlbflush state='on'/>
              <ipi state='on'/>
            </hyperv>
            <kvm>
              <hidden state='on'/>
            </kvm>
          </features>
          
          <cpu mode='host-passthrough' check='none' migratable='on'>
            ${if cpuPinning then "<topology sockets='1' dies='1' cores='4' threads='1'/>" else ""}
            <cache mode='passthrough'/>
          </cpu>
          
          <clock offset='localtime'>
            <timer name='rtc' tickpolicy='catchup'/>
            <timer name='pit' tickpolicy='delay'/>
            <timer name='hpet' present='no'/>
            <timer name='hypervclock' present='yes'/>
          </clock>
          
          <devices>
            <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>
            
            <!-- VirtIO SCSI Controller for thin provisioning / TRIM pass-through -->
            <controller type='scsi' index='0' model='virtio-scsi'/>
            
            <!-- Sparse ZVOL Disk with TRIM support (discard='unmap') -->
            <disk type='block' device='disk'>
              <driver name='qemu' type='raw' cache='none' io='native' discard='unmap'/>
              <source dev='/dev/zvol/razer/nixos/safe/encrypted/user/win-vm'/>
              <target dev='sda' bus='scsi'/>
              <address type='drive' controller='0' bus='0' target='0' unit='0'/>
            </disk>
            
            <!-- Default Network -->
            <interface type='network'>
              <mac address='52:54:00:11:22:33'/>
              <source network='default'/>
              <model type='virtio'/>
            </interface>

            <!-- Intel SR-IOV Passthrough (Automatically targets first VF at 00:02.1) -->
            <hostdev mode='subsystem' type='pci' managed='yes'>
              <source>
                <address domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
              </source>
            </hostdev>

            <!-- Looking Glass Shared Memory -->
            <shmem name='looking-glass'>
              <model type='ivshmem-plain'/>
              <size unit='M'>64</size>
            </shmem>

            <!-- Scream Audio Shared Memory -->
            <shmem name='scream-ivshmem'>
              <model type='ivshmem-plain'/>
              <size unit='M'>2</size>
            </shmem>

            <!-- Inputs -->
            <input type='tablet' bus='usb'/>
            <input type='keyboard' bus='usb'/>
            <input type='mouse' bus='ps2'/>

            <!-- Basic virtual display just for initial OS installation -->
            <graphics type='spice' autoport='yes'>
              <listen type='address'/>
              <image compression='off'/>
            </graphics>
            <video>
              <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
            </video>
          </devices>
        </domain>
      ''}
    '';
  };
}
