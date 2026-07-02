{ den, ... }: {
  den.schema.host.includes = [
    (den.batteries.import-tree.provides.host ./hosts)
  ];
  den.default.includes = [ den.aspects.sshkeys ];
}
