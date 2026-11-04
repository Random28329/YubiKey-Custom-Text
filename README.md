# YubiKey Text Store

Store small pieces of text on a FIDO2 security key (e.g. YubiKey) using passkeys. No install, no cloud. Everything stays between your browser and the key.

## What it does

- **Normal mode:** creates a passkey whose username, display name and user ID hold your own text (up to 64 bytes each). The username is visible in Yubico Authenticator.
- **largeBlob mode:** also stores up to about 4 KB of encrypted text in the key's largeBlob storage (CTAP 2.1, YubiKey firmware 5.7+). You can read, edit and clear it later.

> **Either method takes 1 passkey slot on your key per entry.**

## How it works

1. `start.bat` asks for a URL name (or generates a random one) and runs a tiny local web server with built-in PowerShell, listening only on 127.0.0.1.
2. The page opens at `http://<name>.localhost:8000` and uses the standard WebAuthn API to create a discoverable passkey for that name, with your text in its fields.
3. In largeBlob mode, the page signs in with that passkey and writes or reads its largeBlob. The browser and key encrypt the data with a key that is only released after PIN + touch.

Each entry is bound to its URL name, so other websites can't access it.

## Reading your data

| | Normal mode | largeBlob mode |
|---|---|---|
| Yubico Authenticator app (e.g. Windows, Android) | URL name + username visible (after PIN) | URL name + username visible, **largeBlob text not visible** |
| This page | Key (user ID) via *Read back Key* | largeBlob text via *Read largeBlob* |

Either mode uses **1 passkey slot** per entry (25 slots on older YubiKeys, 100 on firmware 5.7+).

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

**About the 4,096-byte largeBlob size:** Yubico's docs state 4,096 bytes on firmware 5.7.0+ and 1,024 bytes on 5.5.x/5.6.x ([source](https://docs.yubico.com/hardware/yubikey/yk-tech-manual/yk5-firmware-5.7.html)). That statement is for the YubiKey 5 Series. Yubico lists blob storage as supported on the Security Key Series with 5.7, but doesn't state its size, so the same 4,096 bytes is assumed. To check your key:
- **Exact:** a direct-to-key tool (e.g. libfido2's `fido2-token`, run as admin on Windows) shows the key's `maxSerializedLargeBlobArray`.
- **Practical:** save bigger and bigger text on the page. If saves fail at around 1,000 bytes on the counter, your key has 1,024. If they work up to around 4,000, it has 4,096.

## Requirements

- Windows 10/11, Chrome, Edge or Firefox
- A FIDO2 key with a PIN set
- For largeBlob: a key and browser that support it (the page checks for you)

## Notes

- The same URL name + the same Key (user ID) replaces the existing passkey. The page warns you first.
- Clear a passkey's largeBlob before deleting the passkey, or its data stays stuck on the key.
- Anyone with your key **and** your PIN can read the stored text. Keep another backup of anything important.

## Tested on

- YubiKey Security Key C NFC only, on Windows 11 with Firefox. Other keys, browsers and systems may behave differently.

## Disclaimer

Use at your own risk. This is an unofficial tool, not affiliated with Yubico. Using a security key for storage isn't an officially supported feature. Don't rely on it as the only copy of anything important.

## Files

- `start.bat`: local server + launcher
- `yubikey-text-store.html`: the page
- `wipe-largeblob.py`: optional, shows largeBlob usage and wipes all largeBlob data

## OPTIONAL ---- Clearing and wiping ALL largeBlob

**The page can't fully remove a largeBlob.** To keep it simple (no install, no admin), *Clear largeBlob* replaces your text with a tiny empty marker (about 30–40 bytes). Browsers have no way to fully delete an entry.

**Delete order matters.** If you delete a largeBlob passkey in Yubico Authenticator *without* clearing it first, its data stays on the key as an orphan: unreadable, but still taking space. Always **Clear first, then delete the passkey**.

**To wipe ALL largeBlob data from the key** (including orphans and the empty markers), use `wipe-largeblob.py`. It uses Yubico's official [python-fido2](https://github.com/Yubico/python-fido2) library. **Passkeys and PIN are not touched**, but it erases largeBlob data from *every* app and site on the key (e.g. other apps that store data there).

1. Install Python from [python.org](https://www.python.org/downloads/) (Windows installer, 64-bit). During setup, tick **Add python.exe to PATH**.
2. Open Command Prompt and run:
   ```
   pip install fido2
   ```
3. Open Command Prompt **as administrator** (Windows only lets admin programs talk to the key directly), go to the folder with the script, and run:
   ```
   cd C:\path\to\folder
   python wipe-largeblob.py
   ```
4. With only one key plugged in, it shows the largeBlob size, used and free space, and the number of entries. Type **YES** to wipe (anything else exits without changes), enter your PIN, and touch the key if it blinks.

You can also run it just to check how much largeBlob space is used. Checking needs no PIN.
17 bytes means empty. It’s the smallest the largeBlob space can be:

1 byte for an empty list
16 bytes for its checksum





## SCREENSHOTS

<img width="1072" height="299" alt="1" src="https://github.com/user-attachments/assets/64effc0b-c83d-4a43-aa00-5599ef7578c4" />
<img width="1092" height="1088" alt="2" src="https://github.com/user-attachments/assets/f8d6e60c-83b7-44f6-a5a3-277a8dd94bfb" />
<img width="825" height="1359" alt="3" src="https://github.com/user-attachments/assets/6e2b2d8b-e2ba-41bc-84fa-3185120b5f7c" />
<img width="279" height="365" alt="4" src="https://github.com/user-attachments/assets/414ec31e-600e-48bb-a2ce-5e31a37dbccd" />
