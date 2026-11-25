"""Visual/content checks against historical original.png and packed.png.

This does not re-run the processor and does not use OCR. Semantic Tamil
glyph identity and exact diagram meaning remain REVIEW_REQUIRED for
manual inspection where only pixel/structure evidence is available.
"""

from __future__ import annotations

from typing import Any

import numpy as np
from PIL import Image

from .fixture import PAGE_EXPECTATIONS
from .paths import HarnessPaths
from .result import CheckResult, ReferenceRegressionResult


def _load_pair(
    page: int,
    paths: HarnessPaths,
) -> tuple[np.ndarray, np.ndarray] | None:
    original_path = paths.original_png(page)
    packed_path = paths.packed_png(page)
    if not original_path.is_file() or not packed_path.is_file():
        return None
    original = np.asarray(Image.open(original_path).convert("RGB"), dtype=np.uint8)
    packed = np.asarray(Image.open(packed_path).convert("RGBA"), dtype=np.uint8)
    return original, packed


def _color_present(rgb: np.ndarray, mask: np.ndarray, kind: str) -> bool:
    if not mask.any():
        return False
    samples = rgb[mask]
    r = samples[:, 0].astype(np.int16)
    g = samples[:, 1].astype(np.int16)
    b = samples[:, 2].astype(np.int16)
    if kind == "red":
        return bool(((r > 140) & (r > g + 40) & (r > b + 40)).any())
    if kind == "yellow":
        return bool(((r > 160) & (g > 140) & (b < 120) & (r + g > 2 * b + 40)).any())
    if kind == "dark":
        return bool(((r < 80) & (g < 80) & (b < 80)).any())
    return False


def _edge_span(alpha: np.ndarray, axis: str, edge: str, band: int = 16) -> float:
    """Fraction of the edge that still contains opaque ink."""
    height, width = alpha.shape
    if axis == "h":
        strip = alpha[:band] if edge == "start" else alpha[-band:]
        # Collapse the band, then measure coverage across width.
        covered = (strip > 0).any(axis=0)
        return float(covered.mean()) if covered.size else 0.0
    strip = alpha[:, :band] if edge == "start" else alpha[:, -band:]
    covered = (strip > 0).any(axis=1)
    return float(covered.mean()) if covered.size else 0.0


def validate_visual(
    result: ReferenceRegressionResult,
    metrics: dict[str, Any],
    paths: HarnessPaths | None = None,
) -> None:
    paths = paths or HarnessPaths.historical()
    pages = {
        int(page["original_page"]): page for page in (metrics.get("pages") or [])
    }

    result.add(
        CheckResult(
            "visual_validation_scope",
            True,
            detail=(
                "Compares packed.png composited onto white against original.png; "
                "checks opaque RGB identity, transparent packing, colour presence, "
                "and page-7 boundary strokes."
            ),
            limitation=(
                "No OCR is used. Exact Tamil glyph identity, yellow-label wording, "
                "and diagram semantics remain REVIEW_REQUIRED for human inspection. "
                "SSIM from metrics.json is recorded but never used as the sole gate."
            ),
        )
    )

    for page_no in sorted(PAGE_EXPECTATIONS):
        pair = _load_pair(page_no, paths)
        if pair is None:
            result.add(
                CheckResult(
                    f"page_{page_no:02d}_visual_assets",
                    False,
                    detail="original.png or packed.png missing",
                )
            )
            continue
        original, packed = pair
        if original.shape[:2] != packed.shape[:2]:
            result.add(
                CheckResult(
                    f"page_{page_no:02d}_visual_shape",
                    False,
                    detail=f"original={original.shape} packed={packed.shape}",
                )
            )
            continue

        alpha = packed[:, :, 3]
        opaque = alpha == 255
        clear = alpha == 0
        rgb = packed[:, :, :3]
        composite = original.copy()
        composite[clear] = 255

        # Opaque pixels must preserve the original RGB exactly.
        opaque_delta = 0
        if opaque.any():
            opaque_delta = int(
                np.max(
                    np.abs(
                        rgb[opaque].astype(np.int16)
                        - original[opaque].astype(np.int16)
                    )
                )
            )
        result.add(
            CheckResult(
                f"page_{page_no:02d}_opaque_identity",
                opaque_delta == 0 and opaque.any(),
                detail=f"max_delta={opaque_delta} opaque_px={int(opaque.sum())}",
            )
        )

        # Packed convention: transparent RGB is zeroed.
        transparent_rgb_ok = True
        if clear.any():
            transparent_rgb_ok = bool(np.all(rgb[clear] == 0))
        result.add(
            CheckResult(
                f"page_{page_no:02d}_transparent_rgb_zero",
                transparent_rgb_ok,
                detail=f"clear_px={int(clear.sum())}",
            )
        )

        # Foreground-ish dark/coloured original pixels must not be wiped.
        dark = original.max(axis=2) < 90
        saturated = (
            (original.max(axis=2) - original.min(axis=2)) > 40
        ) & (original.max(axis=2) > 80)
        protected = dark | saturated
        cleared = protected & clear
        result.add(
            CheckResult(
                f"page_{page_no:02d}_protected_not_cleared",
                int(cleared.sum()) == 0,
                detail=f"cleared_protected_px={int(cleared.sum())}",
            )
        )

        # Colour anchors for red headings / borders and yellow labels.
        result.add(
            CheckResult(
                f"page_{page_no:02d}_red_present",
                _color_present(original, opaque, "red"),
                detail="red-ish opaque pixels",
            )
        )
        result.add(
            CheckResult(
                f"page_{page_no:02d}_dark_ink_present",
                _color_present(original, opaque, "dark"),
                detail="dark opaque pixels",
            )
        )
        # Yellow labels are common on instruction pages; require presence when
        # the historical metrics show a yellow-capable page by checking the
        # original render for yellow among opaque pixels. Missing yellow on a
        # page that historically had none is recorded as a soft limitation.
        yellow = _color_present(original, opaque, "yellow")
        if page_no in {1, 11, 23, 25, 33}:
            result.add(
                CheckResult(
                    f"page_{page_no:02d}_yellow_present",
                    yellow,
                    detail="yellow-ish opaque pixels",
                )
            )
        else:
            result.add(
                CheckResult(
                    f"page_{page_no:02d}_yellow_probe",
                    True,
                    detail=f"yellow_present={yellow}",
                    limitation=(
                        "Yellow-label wording is not OCR-verified; only colour "
                        "presence is probed where historically expected."
                    ),
                )
            )

        # Border / page-number region: the red frame sits inset from the crop.
        height, width = alpha.shape
        border = np.zeros(alpha.shape, dtype=bool)
        border[45:95, :] = True
        border[height - 95 : height - 40, :] = True
        border[:, 45:95] = True
        border[:, width - 95 : width - 40] = True
        border_opaque = int((opaque & border).sum())
        border_red = _color_present(original, opaque & border, "red")
        result.add(
            CheckResult(
                f"page_{page_no:02d}_border_ink",
                border_opaque > 100 and border_red,
                detail=f"border_opaque_px={border_opaque} red={border_red}",
            )
        )

        # Record historical SSIM without making it the sole gate.
        page_metrics = (pages.get(page_no) or {}).get(
            "metrics_vs_original_on_paper"
        ) or {}
        ssim = float(page_metrics.get("ssim") or 0.0)
        result.add(
            CheckResult(
                f"page_{page_no:02d}_ssim_recorded",
                ssim >= 0.99,
                detail=f"ssim={ssim}",
                limitation=(
                    "SSIM is recorded as supporting evidence only; opaque identity, "
                    "protected-pixel and grid checks are the hard gates."
                ),
            )
        )

        # Recomputed white-composite MAE on opaque pixels must be zero.
        composite_mae = float(
            np.mean(
                np.abs(
                    composite.astype(np.int16) - original.astype(np.int16)
                )
            )
        )
        # Transparent areas become white; MAE over the whole page can be >0.
        # Gate on opaque MAE instead.
        opaque_mae = 0.0
        if opaque.any():
            opaque_mae = float(
                np.mean(
                    np.abs(
                        rgb[opaque].astype(np.int16)
                        - original[opaque].astype(np.int16)
                    )
                )
            )
        result.add(
            CheckResult(
                f"page_{page_no:02d}_opaque_mae",
                opaque_mae == 0.0,
                detail=f"opaque_mae={opaque_mae} full_composite_mae={composite_mae:.4f}",
            )
        )

    # Page 7 bottom / side boundary strokes inside the 9x9 rect.
    page7 = pages.get(7)
    pair7 = _load_pair(7, paths)
    if page7 is not None and pair7 is not None:
        _original7, packed7 = pair7
        yantra = next(
            (
                image
                for image in page7.get("embedded_images") or []
                if image.get("grid_class") == "9x9"
                and image.get("mode") == "segmented"
            ),
            None,
        )
        if yantra is None:
            result.add(
                CheckResult(
                    "page_07_visual_grid",
                    False,
                    detail="9x9 segmented image missing",
                )
            )
        else:
            x0, y0, x1, y1 = [int(v) for v in yantra["rect"]]
            alpha = packed7[y0:y1, x0:x1, 3]
            top = _edge_span(alpha, "h", "start")
            bottom = _edge_span(alpha, "h", "end")
            left = _edge_span(alpha, "v", "start")
            right = _edge_span(alpha, "v", "end")
            # Exact 10×10 line enumeration stays in metrics (h_lines/v_lines).
            # Here we only prove the outer strokes, especially the bottom edge,
            # were not wiped by transparency.
            result.add(
                CheckResult(
                    "page_07_outer_boundaries_present",
                    top >= 0.70 and bottom >= 0.70 and left >= 0.70 and right >= 0.70,
                    detail=(
                        f"top={top:.3f} bottom={bottom:.3f} "
                        f"left={left:.3f} right={right:.3f}"
                    ),
                )
            )
            result.add(
                CheckResult(
                    "page_07_bottom_boundary_present",
                    bottom >= 0.70,
                    detail=f"bottom_span={bottom:.3f}",
                )
            )

    # Page 16: upper irregular chart remains fully opaque; lower 4x4 is segmented.
    page16 = pages.get(16)
    pair16 = _load_pair(16, paths)
    if page16 is not None and pair16 is not None:
        _original16, packed16 = pair16
        opaque_img = next(
            (
                image
                for image in page16.get("embedded_images") or []
                if image.get("mode") == "opaque_fallback"
            ),
            None,
        )
        lower = next(
            (
                image
                for image in page16.get("embedded_images") or []
                if image.get("mode") == "segmented"
                and image.get("grid_class") == "4x4"
            ),
            None,
        )
        if opaque_img is None or lower is None:
            result.add(
                CheckResult(
                    "page_16_visual_roles",
                    False,
                    detail="expected opaque_fallback + segmented 4x4",
                )
            )
        else:
            ox0, oy0, ox1, oy1 = [int(v) for v in opaque_img["rect"]]
            upper = packed16[oy0:oy1, ox0:ox1]
            upper_clear = float((upper[:, :, 3] == 0).mean())
            result.add(
                CheckResult(
                    "page_16_upper_kept_opaque",
                    upper_clear < 0.02,
                    detail=f"upper_clear_fraction={upper_clear:.4f}",
                )
            )
            lx0, ly0, lx1, ly1 = [int(v) for v in lower["rect"]]
            lower_alpha = packed16[ly0:ly1, lx0:lx1, 3]
            lower_clear = float((lower_alpha == 0).mean())
            result.add(
                CheckResult(
                    "page_16_lower_segmented_transparency",
                    lower_clear > 0.05,
                    detail=f"lower_clear_fraction={lower_clear:.4f}",
                )
            )
            result.add(
                CheckResult(
                    "page_16_status_needs_review",
                    page16.get("status") == "NEEDS_REVIEW",
                    detail=str(page16.get("status")),
                )
            )
