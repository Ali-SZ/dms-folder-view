#!/usr/bin/env python3
import sys
import subprocess
import urllib.parse
import shutil
import os
import datetime

def main():
    if len(sys.argv) < 2:
        sys.exit(1)
    target_dir = sys.argv[1]
    
    # 1. Check clipboard MIME types for image formats
    try:
        p_types = subprocess.run(['wl-paste', '--list-types'], capture_output=True, text=True)
        types = p_types.stdout.splitlines()
    except Exception:
        types = []

    image_type = None
    for t in types:
        if t.startswith('image/'):
            image_type = t
            break

    if image_type:
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        ext = "png"
        if "jpeg" in image_type or "jpg" in image_type:
            ext = "jpg"
        
        filename = f"Clipboard_{timestamp}.{ext}"
        dest_path = os.path.join(target_dir, filename)
        
        try:
            with open(dest_path, 'wb') as f:
                subprocess.run(['wl-paste', '-t', image_type], stdout=f)
            sys.exit(0)
        except Exception as e:
            print(f"Error saving image: {e}", file=sys.stderr)
            sys.exit(1)

    # 2. Get clipboard contents for file paths
    try:
        p = subprocess.run(['wl-paste', '-t', 'x-special/gnome-copied-files'], capture_output=True, text=True)
        clip = p.stdout
    except Exception:
        clip = ""
        
    if not clip.strip():
        # Fallback to plain text
        try:
            p = subprocess.run(['wl-paste'], capture_output=True, text=True)
            clip = p.stdout
        except Exception:
            clip = ""
            
    if not clip.strip():
        sys.exit(0)
        
    lines = [line.strip() for line in clip.split('\n') if line.strip()]
    if not lines:
        sys.exit(0)
        
    action = "copy"
    file_lines = []
    
    if lines[0] in ("copy", "cut"):
        action = lines[0]
        file_lines = lines[1:]
    else:
        file_lines = lines
        
    paths = []
    for line in file_lines:
        if line.startswith("file://"):
            line = line[7:]
        # Handle leading localhost/ if present
        if line.startswith("localhost/"):
            line = line[9:]
        # Decode URL
        decoded = urllib.parse.unquote(line)
        if os.path.exists(decoded):
            paths.append(decoded)
            
    if not paths:
        sys.exit(0)
        
    for src in paths:
        try:
            if action == "cut":
                shutil.move(src, target_dir)
            else:
                if os.path.isdir(src):
                    dest = os.path.join(target_dir, os.path.basename(src))
                    shutil.copytree(src, dest, dirs_exist_ok=True)
                else:
                    shutil.copy2(src, target_dir)
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
