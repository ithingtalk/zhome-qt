# ZHome Qt

ZHome / AirMemo client (Qt/QML). Licensed under the [MIT License](LICENSE).

Part of the [ithingtalk](https://github.com/ithingtalk) open-source set.

## Important limitations

- **Native libraries are not included** (`clibs` / `libs` / `thirdparty`, VLC frameworks). Download prebuilts from [https://www.ithingtalk.com/zhome-libs.zip](https://www.ithingtalk.com/zhome-libs.zip) and see [DEPENDENCIES.md](DEPENDENCIES.md).
- **Production AWS IDs are not included.** Copy `awsconfig.json.example` to the path expected by the app and fill in your own Cognito / API Gateway / IoT values.
- This tree is meant for reading and rebuilding with your own credentials and prebuilts — it is **not** a turnkey binary release.

## Configure

1. Copy `cfg/awsconfig.json.example` → `cfg/awsconfig.json` (and optionally `config.json.example` → `config.json`).
2. Place `thirdparty/<platform>/` libraries. See DEPENDENCIES.md.
3. Android signing: set `ANDROID_KEYSTORE_*` environment variables; do not hardcode passwords (see `cmake/android-sign.cmake`).

## License

MIT — see [LICENSE](LICENSE). Third-party components you add (VLC, OpenSSL, AWS SDK, etc.) keep their own licenses; keep NOTICE/attribution when redistributing binaries.
