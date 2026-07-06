{ pkgs, ... }:
let
  inherit (pkgs) fetchurl;
in
{
  boot.kernelPatches = [
    # https://github.com/J-jaeyoung/bad-epoll
    {
      name = "eventpoll: fix ep_remove struct eventpoll / struct file UAF";
      patch = fetchurl {
        name = "eventpoll: fix ep_remove struct eventpoll / struct file UAF";
        url = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/patch/?id=a6dc643c69311677c574a0f17a3f4d66a5f3744b";
        hash = "sha256-MHcd8ZcwT/FG5ds2Zmqnng/EoKjd5Z1qXsd+/Cwl11o=";
      };
    }
  ];
}
