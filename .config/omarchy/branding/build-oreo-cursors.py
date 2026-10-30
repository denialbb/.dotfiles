#!/usr/bin/env python3
"""
Fork and generate a multi-size version of oreo_white_cursors.
Generates sizes: [12, 14, 16, 18, 20, 22, 24, 28, 32, 64]
with correct premultiplied alpha and Bicubic filtering to avoid ringing/halos.
"""

import os
import struct
import shutil
import numpy as np
from PIL import Image

SRC_DIR = "/usr/share/icons/oreo_white_cursors"
DEST_DIR = os.path.expanduser("~/.icons/oreo_white_cursors")
LOCAL_SHARE_DEST = os.path.expanduser("~/.local/share/icons/oreo_white_cursors")
TARGET_SIZES = [12, 14, 16, 18, 20, 22, 24, 28, 32, 64]

def unpremultiply_np(arr):
    out = arr.copy()
    a = out[:, :, 3].astype(np.float32)
    mask = a > 0
    for c in range(3):
        channel = out[:, :, c].astype(np.float32)
        channel[mask] = np.clip(np.round(channel[mask] * 255.0 / a[mask]), 0, 255)
        out[:, :, c] = channel.astype(np.uint8)
    return out

def premultiply_np(arr):
    out = arr.copy()
    a = out[:, :, 3].astype(np.float32) / 255.0
    for c in range(3):
        channel = out[:, :, c].astype(np.float32)
        channel = np.clip(np.round(channel * a), 0, 255)
        out[:, :, c] = channel.astype(np.uint8)
    return out

def parse_xcursor(data):
    magic, header, ver, ntoc = struct.unpack("4sIII", data[:16])
    if magic != b"Xcur":
        raise ValueError("Not an Xcur file")
    chunks = []
    for i in range(ntoc):
        ctype, subtype, pos = struct.unpack("III", data[16 + i*12 : 28 + i*12])
        c_header, c_type, c_subtype, c_ver, width, height, xhot, yhot, delay = struct.unpack("IIIIIIIII", data[pos : pos+36])
        raw_bgra = data[pos+36 : pos+36 + width*height*4]
        
        arr = np.frombuffer(raw_bgra, dtype=np.uint8).reshape((height, width, 4))
        unpre_bgra = unpremultiply_np(arr)
        rgba = unpre_bgra[:, :, [2, 1, 0, 3]]
        img = Image.fromarray(rgba, mode="RGBA")
        
        chunks.append({
            "nominal_size": subtype, "width": width, "height": height,
            "xhot": xhot, "yhot": yhot, "delay": delay,
            "raw_bgra": raw_bgra,
            "img": img
        })
    return chunks

def serialize_xcursor(chunks):
    ntoc = len(chunks)
    header = struct.pack("4sIII", b"Xcur", 16, 0x10000, ntoc)
    toc_offset = 16
    chunks_offset = toc_offset + ntoc * 12
    toc_entries = []
    chunk_bytes = []
    current_pos = chunks_offset
    for c in chunks:
        toc_entries.append(struct.pack("III", 0xfffd0002, c["nominal_size"], current_pos))
        c_hdr = struct.pack("IIIIIIIII", 36, 0xfffd0002, c["nominal_size"], 1, c["width"], c["height"], c["xhot"], c["yhot"], c["delay"])
        chunk_data = c_hdr + c["raw_bgra"]
        chunk_bytes.append(chunk_data)
        current_pos += len(chunk_data)
    return header + b"".join(toc_entries) + b"".join(chunk_bytes)

def generate_multi_size_cursor(src_path, target_sizes):
    with open(src_path, "rb") as f:
        orig_chunks = parse_xcursor(f.read())
    
    by_size = {}
    for c in orig_chunks:
        by_size.setdefault(c["nominal_size"], []).append(c)
        
    base_size = 64 if 64 in by_size else max(by_size.keys())
    base_frames = by_size[base_size]
    
    new_chunks = []
    for sz in sorted(target_sizes):
        if sz in by_size:
            new_chunks.extend(by_size[sz])
        else:
            for f in base_frames:
                scale = sz / base_size
                scaled_w = sz
                scaled_h = sz
                if f["width"] != base_size or f["height"] != base_size:
                    scaled_w = max(1, round(f["width"] * scale))
                    scaled_h = max(1, round(f["height"] * scale))
                
                scaled_img = f["img"].resize((scaled_w, scaled_h), Image.Resampling.BICUBIC)
                arr_rgba = np.array(scaled_img)
                arr_rgba[arr_rgba[:, :, 3] < 6] = 0
                
                arr_bgra = arr_rgba[:, :, [2, 1, 0, 3]]
                arr_pre_bgra = premultiply_np(arr_bgra)
                raw_bgra = arr_pre_bgra.tobytes()
                
                new_chunks.append({
                    "nominal_size": sz,
                    "width": scaled_w,
                    "height": scaled_h,
                    "xhot": min(scaled_w - 1, max(0, round(f["xhot"] * scale))),
                    "yhot": min(scaled_h - 1, max(0, round(f["yhot"] * scale))),
                    "delay": f["delay"],
                    "raw_bgra": raw_bgra
                })
    return serialize_xcursor(new_chunks)

def build_theme():
    if not os.path.exists(SRC_DIR):
        print(f"Error: {SRC_DIR} not found. Install oreo-cursors-bin first.")
        return 1

    src_cursors = os.path.join(SRC_DIR, "cursors")
    dest_cursors = os.path.join(DEST_DIR, "cursors")
    
    if os.path.exists(DEST_DIR):
        shutil.rmtree(DEST_DIR)
    os.makedirs(dest_cursors, exist_ok=True)
    
    entries = sorted(os.listdir(src_cursors))
    files = [e for e in entries if not os.path.islink(os.path.join(src_cursors, e))]
    links = [e for e in entries if os.path.islink(os.path.join(src_cursors, e))]
    
    print(f"Building {len(files)} cursors with premultiplied alpha...")
    for fname in files:
        src_file = os.path.join(src_cursors, fname)
        dest_file = os.path.join(dest_cursors, fname)
        try:
            out_bytes = generate_multi_size_cursor(src_file, TARGET_SIZES)
            with open(dest_file, "wb") as f:
                f.write(out_bytes)
        except Exception as e:
            print(f"Error {fname}: {e}")
            shutil.copy2(src_file, dest_file)
            
    print(f"Copying {len(links)} symlinks...")
    for lname in links:
        src_link = os.path.join(src_cursors, lname)
        target = os.readlink(src_link)
        dest_link = os.path.join(dest_cursors, lname)
        os.symlink(target, dest_link)
        
    for meta in ["index.theme", "cursor.theme"]:
        src_meta = os.path.join(SRC_DIR, meta)
        if os.path.exists(src_meta):
            shutil.copy2(src_meta, os.path.join(DEST_DIR, meta))
            
    os.makedirs(os.path.dirname(LOCAL_SHARE_DEST), exist_ok=True)
    if os.path.islink(LOCAL_SHARE_DEST) or os.path.exists(LOCAL_SHARE_DEST):
        os.remove(LOCAL_SHARE_DEST)
    os.symlink("../../.icons/oreo_white_cursors", LOCAL_SHARE_DEST)
    print("Done rebuilding theme.")

if __name__ == "__main__":
    build_theme()
