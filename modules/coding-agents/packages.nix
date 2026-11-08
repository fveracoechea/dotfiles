{
  pkgs,
  inputs,
}: {
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  operator = inputs.operator.packages.${pkgs.stdenv.hostPlatform.system}.default;
}
