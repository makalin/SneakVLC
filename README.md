# SneakVLC

**SneakVLC** is a P2P “sneakernet-style” file drop system using VLC, QR codes, and minimal NAT traversal. It allows devices to exchange files over local or constrained networks using embedded H.264 video streams and a 2-second optical QR handshake. No traditional file server. No USB stick. Just blink-and-transfer.

---

## 🚀 Features

- 📼 **Headless VLC file embedding** via `x264 --subj q` filler-data trick  
- 📱 **QR-based metadata handshake** (magnet-style: hash + IP)  
- 📡 **libVLC with `network-caching=0`** for real-time streaming  
- 🔁 **LED-friendly QR refreshing** with rate-limiting  
- 🌐 **Go-based NAT punch table** (10-line, rotating)

---

## 📦 Architecture Overview

```

\[SneakVLC Sender]
└─> Embed file → x264 stream → broadcast via VLC
└─> Overlay 2s QR (hash + IP)

\[SneakVLC Receiver (Phone)]
└─> Decode QR via camera → parse magnet-style URI
└─> Connect using libVLC in zero-cache mode
└─> Stream demux → extract embedded file

\[Backend: Go Service]
└─> Minimal NAT-punching table
└─> QR refresh rate-limiting for flicker control

````

---

## 🛠️ Requirements

- VLC with x264 support (headless)
- libVLC for receiving (Android/iOS/Web)
- Go 1.21+ for backend NAT-punch
- ffmpeg (for decoding streams, optional)

---

## ⚙️ Usage

### Sender

```bash
./sneakvlc-send.sh file-to-send.zip
````

* Converts the file into filler-data packets embedded in an H.264 stream.
* Flashes QR (magnet URI) on screen for 2 seconds.
* Starts broadcasting via headless VLC.

### Receiver

* Open camera app (or SneakVLC mobile client)
* Detect QR → start libVLC with `network-caching=0`
* File begins streaming in real-time.

### Backend (Go)

```bash
go run punchtable.go
```

* Accepts incoming punch metadata
* Maintains a 10-line rotating NAT mapping table
* Prevents rapid QR refresh to avoid visible LED flicker

---

## 📡 QR Metadata Format

```
sneakvlc://<sha256_hash>?ip=<host_ip>&port=<udp_port>
```

Example:

```
sneakvlc://3a8b...cf7f?ip=192.168.0.12&port=12345
```

---

## 🧪 Status

* [x] H.264 embedding working (VLC headless)
* [x] Real-time streaming with libVLC
* [x] QR transmission + phone camera decoding
* [ ] Mobile UI (React Native or Flutter)
* [ ] Stream-to-file decoder tool (optional)

---

## 🧠 Inspiration

> A tribute to offline-first design, broadcast resilience, and unconventional bandwidth.

---

## 📜 License

MIT License

---

## 🤖 Contributors

* [@makalin](https://github.com/makalin) – creator and maintainer

---

## 📸 Screenshots

*QR overlay demo and mobile scan preview will be added soon.*

```

No Wi-Fi. No Cloud. Just Code and Light.
