{ runCommand, lib }:

firmware:

let
  args = lib.optionalAttrs (firmware ? meta) { inherit (firmware) meta; };
in

runCommand "${firmware.name}-xz" args ''
  edids=(-path 'lib/firmware/edid/*')
  mkdir -p $out/lib
  (cd ${firmware} && find lib/firmware -type d -print0) |
      (cd $out && xargs -0 mkdir -pv --)
  (cd ${firmware} && find lib/firmware -type f -not "''${edids[@]}" -print0) |
      (cd $out && xargs -0rtP "$NIX_BUILD_CORES" -n1 \
          sh -c 'xz -9c -T1 -C crc32 --lzma2=dict=2MiB "${firmware}/$1" > "$1.xz"' --)
  (cd ${firmware} && find lib/firmware -type l -not "''${edids[@]}") | while read link; do
      target="$(readlink "${firmware}/$link")"
      ln -vs -- "''${target/^${firmware}/$out}.xz" "$out/$link.xz"
  done
  (cd ${firmware} && find lib/firmware -type f "''${edids[@]}" -print0) |
      (cd $out && xargs -0rtP "$NIX_BUILD_CORES" -n1 \
          sh -c 'ln -vs -- "${firmware}/$1" "$out/$1"' --)
''
