# data was from https://archive.ics.uci.edu/dataset/938/regensburg+pediatric+appendicitis
# beforehand: #bash: pip3 install ucimlrepo
import os
import zipfile
import requests
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

from tqdm import tqdm
from PIL import Image
from ucimlrepo import fetch_ucirepo


# fetch dataset 
regensburg_pediatric_appendicitis = fetch_ucirepo(id=938) 
  
# data (as pandas dataframes) 
X = regensburg_pediatric_appendicitis.data.features 
y = regensburg_pediatric_appendicitis.data.targets 
# also labels of images
us_number = dataset.data.original[['US_Number']]

# metadata 
print(regensburg_pediatric_appendicitis.metadata) 
  
# variable information 
print(regensburg_pediatric_appendicitis.variables) 

df = pd.concat([X, y,us_number], axis=1)
# Save dataset
df.to_csv("appendicitis_all.csv", index=False)

X.to_csv("appendicitis_features.csv",index=False)
y.to_csv("appendicitis_targets.csv",index=False)

# images
# Official ultrasound image archive
IMAGE_URL = (
    "https://zenodo.org/records/7669442/files/"
    "US_Pictures.zip?download=1"
)

ZIP_PATH =("US_Pictures.zip")

# Download in chunks
response = requests.get(IMAGE_URL, stream=True)
response.raise_for_status()

total_size = int(response.headers.get("content-length", 0))

with open(ZIP_PATH, "wb") as file:
    with tqdm(
        total=total_size,
        unit="B",
        unit_scale=True,
        desc="Downloading ultrasound images"
    ) as progress:

        for chunk in response.iter_content(chunk_size=1024 * 1024):
            if chunk:
                file.write(chunk)
                progress.update(len(chunk))

print("Download completed!")
