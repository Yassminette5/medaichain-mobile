"""
MEDAIChain — Script de préparation du dataset pour Kaggle
=========================================================
Ce script prépare votre dataset pour l'upload sur Kaggle.

Il crée un dossier prêt à être uploadé comme "Kaggle Dataset" contenant :
  - medical_dataset.jsonl (le dataset)
  - dataset/ (les images)

Usage:
  python prepare_kaggle_dataset.py
"""

import json
import os
import shutil

# Configuration
SOURCE_JSONL = "medical_dataset.jsonl"
SOURCE_IMAGES_DIR = "dataset"
OUTPUT_DIR = "kaggle_upload"


def prepare_kaggle_dataset():
    """Prépare le dataset pour l'upload sur Kaggle."""

    print("=" * 60)
    print("📦 Préparation du dataset pour Kaggle")
    print("=" * 60)

    # Vérifier les fichiers source
    if not os.path.exists(SOURCE_JSONL):
        print(f"❌ Fichier {SOURCE_JSONL} introuvable !")
        return

    if not os.path.exists(SOURCE_IMAGES_DIR):
        print(f"❌ Dossier {SOURCE_IMAGES_DIR} introuvable !")
        return

    # Créer le dossier de sortie
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR)
    os.makedirs(os.path.join(OUTPUT_DIR, "dataset"))

    # Compter les images
    images = [f for f in os.listdir(SOURCE_IMAGES_DIR) if f.endswith(('.jpg', '.jpeg', '.png'))]
    print(f"\n🖼️  Images trouvées : {len(images)}")

    # Copier les images
    print("📋 Copie des images...")
    for img in images:
        src = os.path.join(SOURCE_IMAGES_DIR, img)
        dst = os.path.join(OUTPUT_DIR, "dataset", img)
        shutil.copy2(src, dst)

    # Adapter le JSONL : corriger les chemins d'images (Windows→Linux)
    print("📝 Adaptation du dataset JSONL...")
    count = 0
    with open(SOURCE_JSONL, 'r', encoding='utf-8') as fin, \
         open(os.path.join(OUTPUT_DIR, "medical_dataset.jsonl"), 'w', encoding='utf-8') as fout:
        for line in fin:
            entry = json.loads(line.strip())

            # Corriger le chemin d'image (Windows backslashes → Linux forward slashes)
            if "image" in entry:
                entry["image"] = entry["image"].replace("\\", "/")

            fout.write(json.dumps(entry, ensure_ascii=False) + "\n")
            count += 1

    print(f"\n✅ Dataset préparé dans '{OUTPUT_DIR}/' :")
    print(f"   📄 medical_dataset.jsonl ({count} exemples)")
    print(f"   📁 dataset/ ({len(images)} images)")

    # Calculer la taille totale
    total_size = 0
    for root, dirs, files in os.walk(OUTPUT_DIR):
        for f in files:
            total_size += os.path.getsize(os.path.join(root, f))

    print(f"\n📊 Taille totale : {total_size / 1e6:.1f} MB")

    print()
    print("=" * 60)
    print("📤 PROCHAINES ÉTAPES :")
    print("=" * 60)
    print()
    print("   1. Allez sur https://www.kaggle.com/datasets/new")
    print("   2. Cliquez 'New Dataset'")
    print("   3. Glissez-déposez TOUT le contenu du dossier 'kaggle_upload/'")
    print("   4. Nommez-le : 'medaichain-dataset'")
    print("   5. Cliquez 'Create'")
    print()
    print("   Ensuite dans votre Notebook Kaggle :")
    print("   6. Cliquez 'Add Data' (panneau de droite)")
    print("   7. Cherchez 'medaichain-dataset'")
    print("   8. Ajoutez-le — il sera dans /kaggle/input/medaichain-dataset/")
    print()
    print("=" * 60)


if __name__ == "__main__":
    prepare_kaggle_dataset()
