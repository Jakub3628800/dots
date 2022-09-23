import os
import shutil

elements = [".profile"]

REPO_FOLDER = "/home/jk/dev/dots/home"

for element in elements:

    dst = f"/home/jk/{element}"
    src = f"{REPO_FOLDER}/{element}"
    if os.path.exists(f"~/{element}"):
        shutil.copy(src, dst)

    os.link(dst, src)
