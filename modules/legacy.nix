{ den, ... }: {
  den.schema.host.includes = [
    (den.batteries.import-tree.provides.host ./hosts)
  ];
}
