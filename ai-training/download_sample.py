from datasets import load_dataset
import os
import json

# Configuration
DATASET_NAME = "ekacare/clinical_note_generation_dataset"
OUTPUT_DIR = "./dataset"
SAMPLE_COUNT = 10 # Nombre d'exemples à télécharger

def download_samples():
    """
    Télécharge des exemples de notes cliniques (conseils + ordonnances)
    pour alimenter le dataset d'entraînement.
    """
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"📁 Dossier {OUTPUT_DIR} créé.")

    print(f"📥 Téléchargement de {SAMPLE_COUNT} exemples depuis {DATASET_NAME}...")
    
    try:
        # Note: Certains datasets nécessitent parfois un login (huggingface-cli login)
        dataset = load_dataset(DATASET_NAME, split='train', streaming=True)
        
        count = 0
        for i, example in enumerate(dataset):
            if count >= SAMPLE_COUNT:
                break
                
            # Les noms des colonnes dépendent du dataset choisi
            # Ici on adapte au format attendu par prepare_dataset.py
            file_base = f"sample_{count:03d}"
            
            # 1. Sauvegarde d'un texte factice pour simuler une 'analyse' 
            # (car ce dataset est purement textuel, on imagine l'image de l'analyse)
            with open(os.path.join(OUTPUT_DIR, f"{file_base}.txt"), 'w', encoding='utf-8') as f:
                # On combine les infos pertinentes : Symptômes -> Conseil/Ordonnance
                symptoms = example.get('symptoms', 'N/A')
                advice = example.get('clinical_notes', 'N/A')
                content = f"SYMPTÔMES :\n{symptoms}\n\nCONSEIL ET ORDONNANCE :\n{advice}"
                f.write(content)
            
            # 2. Création d'une image vide (placeholder) pour le test
            # Dans un vrai cas, on utiliserait une vraie image d'analyse
            from PIL import Image, ImageDraw
            img = Image.new('RGB', (400, 200), color = (73, 109, 137))
            d = ImageDraw.Draw(img)
            d.text((10,10), f"Analyse Medicale {file_base}", fill=(255,255,0))
            img.save(os.path.join(OUTPUT_DIR, f"{file_base}.jpg"))
            
            count += 1
            print(f"✅ Exemple {count} sauvegardé.")
            
    except Exception as e:
        print(f"❌ Erreur lors du téléchargement : {e}")
        print("💡 Astuce : Assurez-vous d'avoir 'datasets' et 'Pillow' installés.")

if __name__ == "__main__":
    download_samples()
