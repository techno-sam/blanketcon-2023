import cv2
import tempfile
import os
import urllib.request
out = []
tmp_path = tempfile.mkdtemp()
print(tmp_path)
for i in range(21):
    url = f"https://blanketcon.b-cdn.net/pub/23/nomenclature/{i}.png"
    f_name = os.path.join(tmp_path, f"{i}.png")
    response = urllib.request.urlopen(url)
    data = response.read()
    with open(f_name, "wb") as f:
        f.write(data)
    
    dim = cv2.imread(f_name).shape[:-1][::-1]
    print(dim)
    base = {"width": dim[0], "height": dim[1]}
    base["url"] = url
    base["title"] = f"Slide #{i+1}"
    out.append(base)

import json

print(json.dumps(out, indent=2))

with open(os.path.join(tmp_path, "nomenclature.json"), "w") as f:
    json.dump(out, f, indent=2)