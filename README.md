# YubiKey Text Store

Store small pieces of text on a FIDO2 security key (e.g. YubiKey) using passkeys. No install, no cloud. Everything stays between your browser and the key.

## What it does

- **Normal mode:** creates a passkey whose username, display name and user ID hold your own text (up to 64 bytes each). The username is visible in Yubico Authenticator.
- **largeBlob mode:** also stores up to about 4 KB of encrypted text in the key's largeBlob storage (CTAP 2.1, YubiKey firmware 5.7+). You can read, edit and clear it later.

## How it works

1. `start.bat` asks for a URL name (or generates a random one) and runs a tiny local web server with built-in PowerShell, listening only on 127.0.0.1.
2. The page opens at `http://<name>.localhost:8000` and uses the standard WebAuthn API to create a discoverable passkey for that name, with your text in its fields.
3. In largeBlob mode, the page signs in with that passkey and writes or reads its largeBlob. The browser and key encrypt the data with a key that is only released after PIN + touch.

Each entry is bound to its URL name, so other websites can't access it.

## Limits per field

| Field | Max | Allowed |
|---|---|---|
| URL name | 63 per part, 243 total (parts joined with dots, e.g. `a.b.c`) | letters, digits, dashes (lowercase) |
| Username | 64 bytes | any text |
| Display name | 64 bytes | any text |
| Key (user ID) | 64 bytes | any text |
| largeBlob text | about 4,000 bytes after compression, **shared by all largeBlob entries on the key** | any text |

- 1 byte = 1 character for normal letters, numbers and symbols. Accented letters take 2 bytes, most emoji 4.
- largeBlob in characters: about 4,000–5,000 for random text (passwords, keys) and about 8,000–12,000 for normal writing, because it gets compressed. The page shows the estimated size.
- The key may shorten very long URL names, and may not display the display name.

## Requirements

- Windows 10/11, Chrome, Edge or Firefox
- A FIDO2 key with a PIN set
- For largeBlob: a key and browser that support it (the page checks for you)

## Notes

- The same URL name + the same Key (user ID) replaces the existing passkey. The page warns you first.
- Clear a passkey's largeBlob before deleting the passkey, or its data stays stuck on the key.
- Anyone with your key **and** your PIN can read the stored text. Keep another backup of anything important.

## Files

- `start.bat`: local server + launcher
- `yubikey-text-store.html`: the page

- <img width="825" height="1359" alt="3" src="https://github.com/user-attachments/assets/bb61381e-4c46-49d5-a09d-cadb56d7030d" />
<img width="1092" height="1088" alt="2" src="https://github.com/user-attachments/assets/d4be40f8-e770-4b49-8927-300c1c8ce2d1" />
<img width="1072" height="299" alt="1" src="https://github.com/user-attachments/assets/4a04b21e-0ad7-498a-b514-3efd566fd1b7" />
<img width="279" height="365" alt="4" src="https://github.com/user-attachments/assets/4d633a0c-808e-49f9-a2fe-3adaa3b1758c" />

