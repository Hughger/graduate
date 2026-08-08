from sd_accel.environment import collect


def test_environment_contract():
    report = collect()
    assert report["legacy_build_sbt"] == "build.sbt"
    assert report["legacy_config"] == {
        "rowSize": 32,
        "colSize": 32,
        "dataWidth": 8,
        "pipeline": 2,
        "tLatency": 4,
        "compressionFactor": 4,
        "tileSize": 16,
    }
    assert set(("python", "numpy", "torch", "java", "sbt", "vivado")) <= report.keys()

def test_environment_requires_build_sbt(tmp_path):
    try:
        collect(tmp_path)
    except RuntimeError as error:
        assert str(error) == "missing build.sbt"
    else:
        raise AssertionError("collect() accepted a repository without build.sbt")
