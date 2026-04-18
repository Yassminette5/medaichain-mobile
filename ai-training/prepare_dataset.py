import json
import os

# Configuration
DATA_DIR = './dataset'
OUTPUT_FILE = 'medical_dataset.jsonl'

def prepare_data():
    """
    Parcourt un dossier contenant des images (.jpg, .png) 
    et des fichiers texte (.txt) avec le même nom.
    """
    dataset = []
    
    if not os.path.exists(DATA_DIR):
        print(f"⚠️ Création du dossier {DATA_DIR}. Veuillez y placer vos images et fichiers texte.")
        os.makedirs(DATA_DIR)
        return

    files = os.listdir(DATA_DIR)
    images = [f for f in files if f.endswith(('.jpg', '.jpeg', '.png'))]

    for img in images:
        base_name = os.path.splitext(img)[0]
        txt_file = f"{base_name}.txt"
        
        if txt_file in files:
            with open(os.path.join(DATA_DIR, txt_file), 'r', encoding='utf-8') as f:
                advice = f.read().strip()
            
            # Format pour Llava/Llama-Vision
            entry = {
                "id": base_name,
                "image": os.path.join(DATA_DIR, img),
                "conversations": [
                    {
                        "from": "human",
                        "value": "<image>\nAnalyse cette analyse médicale et donne tes conseils et l'ordonnance."
                    },
                    {
                        "from": "gpt",
                        "value": advice
                    }
                ]
            }
            dataset.append(entry)

    # Sauvegarde au format JSONL
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        for entry in dataset:
            f.write(json.dumps(entry, ensure_ascii=False) + '\n')

    print(f"✅ Dataset créé avec {len(dataset)} exemples dans {OUTPUT_FILE}")

if __name__ == "__main__":
    prepare_data()
