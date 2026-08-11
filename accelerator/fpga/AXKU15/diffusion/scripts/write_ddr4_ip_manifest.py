"""Write provenance for a project-owned AXKU15 DDR4 XCI copy."""

from argparse import ArgumentParser
from hashlib import sha256
import json
from pathlib import Path


def digest(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()


parser = ArgumentParser()
parser.add_argument("--source-xci", type=Path, required=True)
parser.add_argument("--upgraded-xci", type=Path, required=True)
parser.add_argument("--vivado-version", required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()

payload = {
    "part": "xcku15p-ffve1517-2-i",
    "source_sha256": digest(args.source_xci),
    "source_xci": str(args.source_xci),
    "upgraded_sha256": digest(args.upgraded_xci),
    "upgraded_xci": str(args.upgraded_xci),
    "vivado_version": args.vivado_version,
}
args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
