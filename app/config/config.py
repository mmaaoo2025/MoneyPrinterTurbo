import os
import shutil
import socket
import sys
from pathlib import Path

import toml
from loguru import logger

root_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))


def _local_config_dir() -> Path:
    override = os.getenv("MPT_CONFIG_DIR")
    if override:
        return Path(override).expanduser()

    if os.name == "nt":
        base = os.getenv("LOCALAPPDATA") or os.getenv("APPDATA")
        if base:
            return Path(base) / "moneyPrinterTurbo"
        return Path.home() / "AppData" / "Local" / "moneyPrinterTurbo"

    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support" / "moneyPrinterTurbo"

    base = os.getenv("XDG_CONFIG_HOME")
    if base:
        return Path(base) / "moneyPrinterTurbo"
    return Path.home() / ".config" / "moneyPrinterTurbo"


def _private_write_permissions(path: Path) -> None:
    if os.name != "nt":
        os.chmod(path, 0o600)


def _config_file() -> Path:
    override = os.getenv("MPT_CONFIG_FILE")
    if override:
        path = Path(override).expanduser()
    else:
        path = _local_config_dir() / "config.toml"

    path.parent.mkdir(parents=True, exist_ok=True)
    if os.name != "nt":
        os.chmod(path.parent, 0o700)
    return path


config_file = str(_config_file())
legacy_config_file = f"{root_dir}/config.toml"


def load_config():
    # fix: IsADirectoryError: [Errno 21] Is a directory: '/MoneyPrinterTurbo/config.toml'
    if os.path.isdir(config_file):
        shutil.rmtree(config_file)

    if not os.path.isfile(config_file):
        example_file = f"{root_dir}/config.example.toml"
        if os.path.isfile(legacy_config_file):
            shutil.copyfile(legacy_config_file, config_file)
            _private_write_permissions(Path(config_file))
            logger.info(f"migrate project config.toml to local config: {config_file}")
        elif os.path.isfile(example_file):
            shutil.copyfile(example_file, config_file)
            _private_write_permissions(Path(config_file))
            logger.info(f"copy config.example.toml to local config: {config_file}")

    logger.info(f"load config from file: {config_file}")

    try:
        _config_ = toml.load(config_file)
    except Exception as e:
        logger.warning(f"load config failed: {str(e)}, try to load as utf-8-sig")
        with open(config_file, mode="r", encoding="utf-8-sig") as fp:
            _cfg_content = fp.read()
            _config_ = toml.loads(_cfg_content)
    return _config_


def save_config():
    with open(config_file, "w", encoding="utf-8") as f:
        _cfg["app"] = app
        _cfg["azure"] = azure
        _cfg["personal_voice"] = personal_voice
        _cfg["siliconflow"] = siliconflow
        _cfg["ui"] = ui
        f.write(toml.dumps(_cfg))
    _private_write_permissions(Path(config_file))


_cfg = load_config()
app = _cfg.get("app", {})
whisper = _cfg.get("whisper", {})
proxy = _cfg.get("proxy", {})
azure = _cfg.get("azure", {})
personal_voice = _cfg.get("personal_voice", {})
siliconflow = _cfg.get("siliconflow", {})
ui = _cfg.get(
    "ui",
    {
        "hide_log": False,
    },
)

hostname = socket.gethostname()

log_level = _cfg.get("log_level", "DEBUG")
listen_host = _cfg.get("listen_host", "0.0.0.0")
listen_port = _cfg.get("listen_port", 8080)
project_name = _cfg.get("project_name", "MoneyPrinterTurbo")
project_description = _cfg.get(
    "project_description",
    "<a href='https://github.com/harry0703/MoneyPrinterTurbo'>https://github.com/harry0703/MoneyPrinterTurbo</a>",
)
project_version = _cfg.get("project_version", "1.2.7")
reload_debug = False

app["redis_host"] = os.getenv(
    "MPT_APP_REDIS_HOST",
    os.getenv("REDIS_HOST", app.get("redis_host", "localhost")),
)

imagemagick_path = app.get("imagemagick_path", "")
if imagemagick_path and os.path.isfile(imagemagick_path):
    os.environ["IMAGEMAGICK_BINARY"] = imagemagick_path

ffmpeg_path = app.get("ffmpeg_path", "")
if ffmpeg_path and os.path.isfile(ffmpeg_path):
    os.environ["IMAGEIO_FFMPEG_EXE"] = ffmpeg_path

logger.info(f"{project_name} v{project_version}")
