"""
wipe-largeblob.py - empties ALL largeBlob data on a FIDO2 security key.
Passkeys and the PIN are NOT touched.

Uses Yubico's official python-fido2 library:  pip install fido2
Windows: run from a Command Prompt opened "as administrator".
"""
import getpass
import sys

from fido2 import cbor
from fido2.ctap2 import Ctap2
from fido2.ctap2.blob import LargeBlobs
from fido2.ctap2.pin import ClientPin
from fido2.hid import CtapHidDevice



def pick_device():
    devs = list(CtapHidDevice.list_devices())
    if not devs:
        sys.exit("No FIDO2 key found. Plug it in. On Windows, run as administrator.")
    if len(devs) > 1:
        sys.exit("More than one FIDO2 key found. Unplug the others and try again.")
    return devs[0]


def main():
    dev = pick_device()
    ctap = Ctap2(dev)
    info = ctap.info

    if not LargeBlobs.is_supported(info):
        sys.exit("This key does not support largeBlob. Nothing to do.")

    # Reading needs no PIN (entries are encrypted anyway)
    entries = LargeBlobs(ctap).read_blob_array()
    total = info.max_large_blob
    used = len(cbor.encode(list(entries))) + 16   # stored data + 16-byte checksum
    print(f"Key:            {dev.product_name or 'FIDO2 key'}")
    print(f"largeBlob size: {total} bytes")
    print(f"Used:           {used} bytes ({used * 100 // total}%)")
    print(f"Free:           {total - used} bytes")
    print(f"Entries stored: {len(entries)}")
    for i, e in enumerate(entries, 1):
        print(f"  entry {i}: {len(cbor.encode(e))} bytes (encrypted, owner unknown)")

    if not entries:
        print("\nlargeBlob storage is already empty. Nothing to do.")
        return

    print("\nThis deletes ALL largeBlob entries on the key, from every app and website,")
    print("including any you still need. It cannot be undone. Passkeys and PIN stay.")
    if input('Type YES to wipe (anything else just exits): ').strip() != "YES":
        print("Nothing was changed.")
        return

    pin = getpass.getpass("FIDO2 PIN: ")
    client_pin = ClientPin(ctap)
    token = client_pin.get_pin_token(pin, ClientPin.PERMISSION.LARGE_BLOB_WRITE)

    print("Wiping... (touch the key if it blinks)")
    LargeBlobs(ctap, client_pin.protocol, token).write_blob_array([])

    left = LargeBlobs(ctap).read_blob_array()
    if left:
        sys.exit(f"Something went wrong: {len(left)} entries still there.")
    print("Done. largeBlob storage is empty. Your passkeys and PIN are unchanged.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nCancelled.")
    except Exception as e:
        sys.exit(f"Error: {e}")
