#!/usr/bin/env python3
"""Package an already staged FDS/Smokeview bundle with a Finder install layout."""

import argparse
from pathlib import Path
import shlex

import dmgbuild
from PIL import Image, ImageDraw, ImageFont


FDS_VARS = r'''# Source this file from bash or zsh after copying the FDS6 folder.
if [ -n "${BASH_VERSION:-}" ]; then
  _fds_vars_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  eval '_fds_vars_file="${(%):-%x}"'
else
  echo "Source FDSVARS.sh from bash or zsh." >&2
  return 1
fi
_fds_vars_dir="$(cd "$(dirname "$_fds_vars_file")" && pwd -P)"
export FDS_HOME="$(cd "$_fds_vars_dir/.." && pwd -P)"
for _fds_path in "$FDS_HOME/bin" "$FDS_HOME/smvbin" "$FDS_HOME/bin/openmpi/bin"; do
  case ":${PATH:-}:" in
    *":$_fds_path:"*) ;;
    *) export PATH="$_fds_path:${PATH:-}" ;;
  esac
done
export OPAL_PREFIX="$FDS_HOME/bin/openmpi"
export PRTE_PREFIX="$OPAL_PREFIX" PMIX_PREFIX="$OPAL_PREFIX"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-4}"
export TMPDIR=/tmp
unset _fds_vars_file _fds_vars_dir _fds_path
'''

INSTALL_MENU = r'''#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SOURCE=$HERE/FDS6
finish() { printf '\nPress Enter to close.'; read -r _ || true; }
trap finish EXIT
echo "FDS 6 / Smokeview macOS installer"
echo "1) Install to /Applications/FDS6"
echo "2) Copy to ~/Downloads/$EXTRACT_NAME"
echo "3) Copy to another directory"
echo "q) Quit"
read -r -p "Select an option [1]: " choice
case "$choice" in
  ''|1) destination=/Applications/FDS6 ;;
  2) destination=$HOME/Downloads/$EXTRACT_NAME ;;
  3)
    read -r -p "Parent directory (for example, ~/Desktop): " parent
    case "$parent" in '~') parent=$HOME ;; '~/'*) parent=$HOME/${parent#\~/} ;; esac
    [ -n "$parent" ] || { echo "No directory entered."; exit 1; }
    destination=$parent/$EXTRACT_NAME ;;
  q|Q) exit 0 ;;
  *) echo "Unknown option."; exit 1 ;;
esac
[ -d "$SOURCE" ] || { echo "FDS6 folder not found beside this menu."; exit 1; }
mkdir -p "$(dirname "$destination")"
destination="$(cd "$(dirname "$destination")" && pwd -P)/$(basename "$destination")"
source_real=$(cd "$SOURCE" && pwd -P)
case "$destination" in
  "$source_real"|"$source_real"/*) echo "Choose a location outside the mounted FDS6 folder."; exit 1 ;;
esac
if [ -e "$destination" ] || [ -L "$destination" ]; then
  read -r -p "Replace $destination? [y/N]: " answer
  case "$answer" in y|Y|yes|YES) ;; *) echo "Cancelled."; exit 0 ;; esac
fi
if [ -w "$(dirname "$destination")" ]; then
  rm -rf "$destination"
  ditto "$SOURCE" "$destination"
else
  echo "Administrator access is needed to install in this directory."
  sudo -v
  sudo rm -rf "$destination"
  sudo ditto "$SOURCE" "$destination"
fi
echo "Installed: $destination"
echo "To use FDS and Smokeview in Terminal:"
printf '  source "%s/bin/FDSVARS.sh"\n' "$destination"
echo "Add that line to ~/.zprofile (zsh) or ~/.bash_profile (bash) for future sessions."
'''


def background(path):
    # Match the CFAST DMG window, using standard Finder folder/file icons.
    for scale in (1, 2):
        image = Image.new("RGB", (720 * scale, 420 * scale), (247, 249, 252))
        draw = ImageDraw.Draw(image)
        fonts = Path("/System/Library/Fonts/Supplemental")
        title = ImageFont.truetype(str(fonts / "Arial Bold.ttf"), 30 * scale)
        caption = ImageFont.truetype(str(fonts / "Arial.ttf"), 16 * scale)
        draw.text((360 * scale, 54 * scale), "Install FDS 6", font=title,
                  fill=(35, 44, 58), anchor="mt")
        draw.text((360 * scale, 98 * scale),
                  "Drag FDS6 to Applications, or run the Terminal install menu.",
                  font=caption, fill=(86, 100, 120), anchor="mt")
        draw.line([(170 * scale, 235 * scale), (205 * scale, 235 * scale)],
                  fill=(86, 100, 120), width=3 * scale)
        draw.polygon([(205 * scale, 235 * scale), (195 * scale, 229 * scale),
                      (195 * scale, 241 * scale)], fill=(86, 100, 120))
        target = path if scale == 1 else path.with_name(path.stem + "@2x.png")
        image.save(target)


def prepare(dist, volume_name):
    for name in ("bin/fds", "bin/fds2ascii", "bin/test_mpi", "smvbin/smokeview",
                 "bin/openmpi/bin/mpirun", "Documentation/bundle_config.sh"):
        if not (dist / name).is_file():
            raise SystemExit(f"Staged bundle is incomplete: missing {dist / name}")
    for name in ("FDS_Config_Management_Plan", "FDS_Technical_Reference_Guide", "FDS_User_Guide",
                 "FDS_Validation_Guide", "FDS_Verification_Guide", "SMV_Technical_Reference_Guide",
                 "SMV_User_Guide", "SMV_Verification_Guide"):
        if not (dist / "Documentation" / (name + ".pdf")).is_file():
            raise SystemExit(f"Staged bundle is incomplete: missing {name}.pdf")
    work = dist.parent / "dmg"
    work.mkdir(exist_ok=True)
    (dist / "bin/FDSVARS.sh").write_text(FDS_VARS)
    readme = f'''{volume_name} for macOS

Drag FDS6 onto Applications to install in /Applications/FDS6. Finder will ask before replacing an existing FDS6 folder. You may also copy FDS6 to any writable location.

Alternatively, double-click Terminal Install Menu.command to open a Terminal window with choices for installation to Applications, Downloads, or another directory. If it does not open in Terminal, right-click it and choose Open With > Terminal.

After copying, run this in Terminal:
  source "/Applications/FDS6/bin/FDSVARS.sh"

This adds fds, smokeview, and mpirun to your PATH. To keep the settings, add that source line to ~/.zprofile (zsh) or ~/.bash_profile (bash). If you copied FDS6 elsewhere, use that location in the source command.

Manuals are in FDS6/Documentation and examples are in FDS6/Examples.

This is a test bundle; it is not Developer ID signed or notarized.
'''
    if (dist / "Documentation/manuals_test.txt").exists():
        readme += "Manual revisions were allowed to differ from the executables for this packaging test.\n"
    (work / "README.txt").write_text(readme)
    (dist / "README.txt").write_text(readme)
    menu = work / "Terminal Install Menu.command"
    # Keep the shebang first so Finder can launch the menu directly.
    first, rest = INSTALL_MENU.split("\n", 1)
    menu.write_text(first + "\nEXTRACT_NAME=" + shlex.quote(dist.name) + "\n" + rest)
    menu.chmod(0o755)
    background_path = work / "background.png"
    background(background_path)
    return {
        "format": "UDZO", "filesystem": "HFS+", "compression_level": 9,
        "files": [(str(dist), "FDS6"), str(work / "README.txt"), str(menu)],
        "symlinks": {"Applications": "/Applications"},
        "background": str(background_path), "hide": [".background.tiff"],
        "window_rect": ((120, 120), (720, 420)), "default_view": "icon-view",
        "show_status_bar": False, "show_tab_view": False, "show_toolbar": False,
        "show_pathbar": False, "show_sidebar": False, "arrange_by": None,
        "icon_size": 96, "text_size": 16,
        "icon_locations": {"FDS6": (105, 235), "Applications": (275, 235),
                           "README.txt": (455, 235), "Terminal Install Menu.command": (625, 235),
                           ".background.tiff": (1000, 1000)},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("staged_bundle", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--volume-name", required=True)
    args = parser.parse_args()
    settings = prepare(args.staged_bundle.resolve(), args.volume_name)
    dmgbuild.build_dmg(str(args.output.resolve()), args.volume_name, settings=settings,
                       detach_retries=10)


if __name__ == "__main__":
    main()
