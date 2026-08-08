"""Local-only, deterministic SD1.5 ResNetBlock tensor capture."""

from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Any

import numpy as np

from .manifest import CaptureManifest



def _require_torch() -> Any:
    try:
        import torch
    except ImportError as exc:
        raise RuntimeError("capture requires: pip install -e .[model]") from exc
    return torch


def _resolve_module(root: Any, dotted_path: str) -> Any:
    node = root
    for part in dotted_path.split("."):
        node = node[int(part)] if part.isdecimal() else getattr(node, part)
    return node



def _parameter_arrays(block: Any) -> dict[str, np.ndarray]:
    arrays: dict[str, np.ndarray] = {}
    for prefix in ("norm1", "conv1", "time_emb_proj", "norm2", "conv2", "conv_shortcut"):
        module = getattr(block, prefix, None)
        if module is not None:
            for field in ("weight", "bias"):
                value = getattr(module, field, None)
                if value is not None:
                    arrays[f"{prefix}_{field}"] = value.detach().cpu().numpy().astype(np.float16)
    return arrays


def capture_block(model_path: str | Path, block_path: str, timestep: int, seed: int, output_dir: str | Path) -> CaptureManifest:
    """Capture one equal-channel SD1.5 block without downloading model files."""
    torch = _require_torch()
    model_dir = Path(model_path).expanduser().resolve()
    if not model_dir.is_dir():
        raise FileNotFoundError(f"local SD1.5 model directory not found: {model_dir}")
    try:
        from diffusers import UNet2DConditionModel
    except ImportError as exc:
        raise RuntimeError("capture requires: pip install -e .[model]") from exc

    torch.manual_seed(seed)
    torch.use_deterministic_algorithms(True)
    model = UNet2DConditionModel.from_pretrained(model_dir, subfolder="unet", local_files_only=True).eval()
    block = _resolve_module(model, block_path)
    cin, cout = int(block.conv1.in_channels), int(block.conv2.out_channels)
    if cin != cout:
        raise ValueError(f"Cin ({cin}) != Cout ({cout}); residual projection is not enabled")
    generator = torch.Generator(device="cpu").manual_seed(seed)
    sample_side = int(model.config.sample_size)
    sample = torch.randn(
        (1, int(model.config.in_channels), sample_side, sample_side),
        generator=generator,
        dtype=torch.float32,
    )
    encoder_hidden_states = torch.zeros(
        (1, 77, int(model.config.cross_attention_dim)), dtype=torch.float32
    )
    timesteps = torch.tensor([timestep], dtype=torch.long)
    captured: dict[str, Any] = {}

    def pre_hook(_module: Any, args: tuple[Any, ...]) -> None:
        captured["input"] = args[0].detach().cpu()
        captured["temb"] = args[1].detach().cpu()

    def output_hook(_module: Any, _args: tuple[Any, ...], output: Any) -> None:
        captured["output_fp16"] = output.detach().cpu().to(torch.float16)

    pre = block.register_forward_pre_hook(pre_hook)
    post = block.register_forward_hook(output_hook)
    try:
        with torch.no_grad():
            model(sample, timesteps, encoder_hidden_states=encoder_hidden_states)
    finally:
        pre.remove()
        post.remove()

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    arrays = _parameter_arrays(block)
    arrays.update({"input": captured["input"].numpy().astype(np.float16), "temb": captured["temb"].numpy().astype(np.float16), "output_fp16": captured["output_fp16"].numpy()})
    npz_path = output_dir / "tensors.npz"
    np.savez_compressed(npz_path, **arrays)
    digest = hashlib.sha256(npz_path.read_bytes()).hexdigest()
    (output_dir / "tensors.sha256").write_text(f"{digest}  {npz_path.name}\n", encoding="utf-8")
    manifest = CaptureManifest(model_dir.name, block_path, timestep, seed, tuple(arrays["input"].shape), tuple(arrays["output_fp16"].shape), "float16")
    manifest.save(output_dir / "manifest.json")
    return manifest
