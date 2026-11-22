{ pkgs, lib, config, options, ... }@args:

let
  forceLeaves = val:
    if val ? _type then
      val
    else if builtins.isAttrs val && !(val ? type && val ? outPath) then
      builtins.mapAttrs (_: forceLeaves) val
    else if builtins.isList val then
      val
    else
      lib.mkForce val;

  rawModules = [
    ./openssh.nix
    ./mirror.nix
    ./network.nix
    ./chinese.nix
    ./labwc.nix
    ./packages.nix
    ./user.nix
    ./profile.nix
    ./shell.nix
  ];

  forceModule = path: {
    config = forceLeaves (
      let
        m = import path;
        evaluated = if builtins.isFunction m then m args else m;
      in
      if evaluated ? config then evaluated.config else evaluated
    );
  };
in
{
  imports = map forceModule rawModules;
}
