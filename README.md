
# waf-bypasser

**waf-bypasser** is a simple Bash-based automation tool that helps bypass basic Web Application Firewalls (WAFs) by generating a range of obfuscated payloads and testing them against a target URL.

## ⚙️ Features

- Automated payload generation using custom patterns
- Basic WAF evasion techniques (URL encoding, case manipulation, keyword obfuscation, etc.)
- Multi-payload execution loop
- Easy-to-extend architecture
- Lightweight and written entirely in Bash

## 📦 Requirements

- `curl`
- `sed`
- `awk`

Install them on Debian/Ubuntu:
```bash
sudo apt update && sudo apt install curl sed awk
````

## 🚀 Usage

```bash
./waf-bypasser.sh -u "http://target.com/page.php?id=FUZZ"
```

### Options

| Flag                 | Description                                               |
| -------------------- | --------------------------------------------------------- |
| `-u` or `--url`      | The target URL with `FUZZ` as a placeholder for injection |
| `-w` or `--wordlist` | (Optional) Custom wordlist file for payloads              |
| `-h` or `--help`     | Show help message                                         |

Example:

```bash
./waf-bypasser.sh -u "http://example.com/page.php?id=FUZZ" -w payloads.txt
```

## 🔐 Disclaimer

This tool is intended for **educational and authorized testing** purposes **only**. Do not use it on systems you do not own or have explicit permission to test.

## 🛠️ TODO

* Add support for POST requests
* Add proxy/Tor routing
* Export successful payloads to file
* Parallel request option for speed

## 🙏 Acknowledgements

* Inspired by tools like [wfuzz](https://github.com/xmendez/wfuzz) and [sqlmap](https://github.com/sqlmapproject/sqlmap)

---

**Author:** \[occupyashanti]
**License:** MIT

```


