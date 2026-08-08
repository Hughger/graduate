from sd_accel.traffic import estimate_traffic


def test_fused_traffic_counts_common_data_and_reduces_intermediates() -> None:
    report = estimate_traffic((1, 320, 64, 64))

    assert report["common_bytes"]["input"] > 0
    assert report["common_bytes"]["weights"] > 0
    assert report["common_bytes"]["temb"] > 0
    assert report["common_bytes"]["output"] > 0
    assert report["fused_bytes"] < report["unfused_bytes"]
    assert report["intermediate_bytes"]["fused"] == 0
    assert report["intermediate_bytes"]["unfused"] > 0
    assert report["intermediate_reduction"] == 1.0
