{ config, pkgs, lib, ... }:

let
  withdir = pkgs.writeShellScriptBin "withdir" (builtins.readFile ./scripts/sh/withdir);
  clone-commit = pkgs.writeShellScriptBin "clone-commit" (builtins.readFile ./scripts/sh/clonecomit);
  addr6 = pkgs.writeShellScriptBin "addr6" ''
    ip addr show dev $1 scope global | awk '{if ($1=="inet6") {print $2}}'
  '';
  drop-caches = pkgs.writeShellScriptBin "drop-caches" ''
    sync; echo 3 > /proc/sys/vm/drop_caches
  '';
  exectime = pkgs.writeShellScriptBin "exectime" ''
    res1=$(date +%s.%N)
    $@
    res2=$(date +%s.%N)
    dt=$(echo "$res2 - $res1" | bc)
    dd=$(echo "$dt/86400" | bc)
    dt2=$(echo "$dt-86400*$dd" | bc)
    dh=$(echo "$dt2/3600" | bc)
    dt3=$(echo "$dt2-3600*$dh" | bc)
    dm=$(echo "$dt3/60" | bc)
    ds=$(echo "$dt3-60*$dm" | bc)
    LC_NUMERIC=C printf "\nFinished with: %d:%02d:%02d:%02.4f\n" $dd $dh $dm $ds
  '';
in
{
  environment.systemPackages = with pkgs; [
    withdir
    clone-commit
    addr6
    drop-caches
    exectime
  ];
}
