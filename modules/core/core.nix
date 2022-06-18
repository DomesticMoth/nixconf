{ config, pkgs, lib, ... }:

{
  imports = [
    ./scripts.nix
    ../../channels/hm/a8d00f5c038cf7ec54e7dac9c57b171c1217f008/chnl/nixos
  ];

  nix.autoOptimiseStore = true;
  nix.gc.automatic = lib.mkForce false;
  nixpkgs.config.allowUnfree = false;
  system.autoUpgrade.enable = false;

  security.protectKernelImage = true; # Prevent replacing the running kernel image
  security.forcePageTableIsolation = true;
  security.virtualisation.flushL1DataCache = "always"; # Reduce performance!

  boot.cleanTmpDir = true;
  boot.tmpOnTmpfs = true;
  boot.consoleLogLevel = 0; # show all log
  boot.kernelModules  = [ "fuse" ];

  fileSystems = {
    "/".options = [ "noatime" "nodiratime" ]; # Add "discard" ?
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "noatime" "noexec" "nosuid" "nodev" "mode=1777" ];
    };
  };

  users = {
    mutableUsers = false;
    users.admin = {
      isNormalUser = true;
      extraGroups = [ 
        "wheel"
        "audio"
        "sound"
        "video"
        "input"
        "tty"
        "power"
        "games"
        "scanner"
        "storage"
        "optical"
      ];
      home = "/home/admin";
      createHome = true;
      useDefaultShell = true;
      #password = "admin";
    };
    users.root.hashedPassword = null;
  };

  # Enable zram swap
  zramSwap = {
    enable = true;
    priority = 1000;
    algorithm = "zstd";
    numDevices = 1;
    swapDevices = 1;
    memoryPercent = 50;
  };

  # Enable KSM
  hardware.ksm.enable = true;
  hardware.ksm.sleep = null; # Default

  # Doc
  documentation.dev.enable = true;
  documentation.doc.enable = true;
  documentation.info.enable = true;
  documentation.man.enable = true;  

  # Disable sleep/hibernate/suspend
  services.logind.lidSwitch = lib.mkForce "ignore";
  systemd.targets.sleep.enable = lib.mkForce false;
  systemd.targets.suspend.enable = lib.mkForce false;
  systemd.targets.hibernate.enable = lib.mkForce false;
  systemd.targets.hybrid-sleep.enable = lib.mkForce false;

  networking = {
    usePredictableInterfaceNames = true;
    networkmanager.wifi.macAddress = "random";
    networkmanager.wifi.scanRandMacAddress = true;
    firewall.trustedInterfaces = [ "lo" ];
  }

  environment.shellAliases = {
    # Abbreviations
    e = "exit";
    rf = "rm -rf";
    ll = " exa --oneline -L 1 -T -F --group-directories-first -l";
    la = "exa --oneline -L 1 -T -F --group-directories-first -la";
    ls = "exa --oneline -L 1 -T -F --group-directories-first";
    c = "clear";
    h = "history | rg";
    ch = "cd ~";
    # Nixos
    nswitch = "sudo exectime nixos-rebuild switch";
    ncswitch = "sudo exectime nixos-rebuild switch --option extra-substituters https://cache.nixos.org";
    ncollect = "sudo exectime nix-collect-garbage -d";
    noptimise = "sudo exectime nix-store --optimise";
    npull = "sudo withdir /etc/nixos/nixconf exectime git pull";
    # Etc
    qr = "qrencode -t UTF8 -o -";
    stop = "shutdown now";
    print = "figlet -c -t";
    genpass = "openssl rand 33 | base64";
    pause = "sleep 100000d";
    gtree = "exa --oneline -T -F --group-directories-first -a --git-ignore --ignore-glob .git";
    tree = "exa --oneline -T -F --group-directories-first -a";
    sysstat = "systemctl status";
    journal = "journalctl -u";
    size = "du -shP";
    root = "sudo -i";
    shell-nix = "nix-shell --run fish";
  };

  programs.fish.enable = true;
  
  users.extraUsers.admin.shell = pkgs.fish;
  users.extraUsers.root.shell = pkgs.fish;

  environment.systemPackages = with pkgs; [
    # Basic tools
    sudo
    su
    nano
    git
    wget
    curl
    ripgrep # Better grep
    ipgrep
    killall
    gzip
    unzip
    tar
    ping
    telnet
    openssh
    sshpass
    links2 # Terminal browser

    # Cryptography
    gnupg
    openssl
    cryptsetup
    pinentry-curses

    # For USB devices & windows disks
    ntfs3g

    # Other console tools
    qrencode
    figlet
    bat # A cat(1) clone with syntax highlighting and Git integration
    exa # ls clone
    tmux
    screen

    # Fetchutils
    htop
    sysstat
  ];

  programs.gnupg.agent = {
     enable = true;
     pinentryFlavor = "curses";
  };
  
  virtualisation = {
    docker.enable = false;
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };

  environment.variables = {
    HISTCONTROL = "ignoreboth";
    XDG_DATA_HOME = "/home/admin";
    VISUAL = "nano";
    EDITOR = "nano";
  };

  programs.nano = {
    nanorc = ''
      set linenumbers
      set historylog
      set tabsize 2
      set autoindent
      set constantshow
      set nohelp
      set indicator
      set nowrap
      set tabstospaces
      set unix
      set wordbounds
    '';
    syntaxHighlight = true;
  };

  programs = {
    ssh.askPassword = ""; # Ask with CLI but not GUI dialog
  };

  environment.etc.gitignore.source = ./etc/gitignore;
  
  systemd.services.basegitsetup = {
    script = ''
      git=${pkgs.git} && $git/bin/git config --system http.proxy socks5://127.0.0.1:0 && $git/bin/git config --system user.name "John Doe" && $git/bin/git config --system user.email "" && $git/bin/git config --system core.excludesfile "/etc/gitignore" &&  $git/bin/git config --global core.editor "nano"
    '';
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {User = "root";};
  };

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.root = { pkgs, ... }: {
    home.file.".config/htop/htoprc".source = ./configs/htoprc;
    home.file.".config/fish/config.fish".source = ./configs/config.fish;
  };

  home-manager.users.admin = { pkgs, ... }: 
    home.file.".config/htop/htoprc".source = ./configs/htoprc;
    home.file.".config/fish/config.fish".source = ./configs/config.fish;
  };
}
