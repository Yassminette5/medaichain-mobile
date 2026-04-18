# =============================================================================
# MEDAIChain - Fine-Tuning Modèle IA Médicale sur KAGGLE (SANS Ollama)
# =============================================================================
# Ce notebook fine-tune Llama 3.2 3B Instruct pour analyser des analyses
# médicales (texte extrait par OCR) et produire des diagnostics structurés.
#
# Architecture :
#   Image médicale → OCR (Tesseract) → Texte → Ce modèle → JSON structuré
#
# Le modèle apprend à :
#   - Lire des résultats de laboratoire (texte)
#   - Produire un JSON avec diagnosis, advice, prescription, emergency_level
#
# INSTRUCTIONS :
#   1. Allez sur https://www.kaggle.com → Nouveau Notebook
#   2. Settings → Accelerator → GPU T4 x2
#   3. Uploadez medical_dataset.jsonl comme Dataset Kaggle
#   4. Copiez chaque cellule et exécutez dans l'ordre
# =============================================================================


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  CELLULE 1 : Installation des dépendances                                 ║
# ║  ⚠️ APRÈS CETTE CELLULE : Redémarrez la session puis passez à CELLULE 2   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

!pip install --upgrade pip
!pip install "unsloth[kaggle-new] @ git+https://github.com/unslothai/unsloth.git"
!pip install --no-deps xformers trl peft accelerate bitsandbytes triton

print("=" * 70)
print("Installation terminee !")
print("=" * 70)
print()
print("IMPORTANT : REDEMARREZ LA SESSION MAINTENANT")
print("   1. Menu : Run > Restart Session")
print("   2. Apres le redemarrage, NE RELANCEZ PAS cette cellule")
print("   3. Passez directement a la CELLULE 2")
print("=" * 70)


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  CELLULE 2 : Verification GPU & Chargement du modele Llama 3.2 3B         ║
# ║  (Executez ceci APRES le redemarrage)                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

import torch
import os
import json
import subprocess
import re

print("Verification des GPU...")
result = subprocess.run(
    ['nvidia-smi', '--query-gpu=name,memory.total', '--format=csv'],
    capture_output=True, text=True
)
print(result.stdout)
print(f"GPU detectes : {torch.cuda.device_count()}")
for i in range(torch.cuda.device_count()):
    props = torch.cuda.get_device_properties(i)
    print(f"   GPU {i}: {torch.cuda.get_device_name(i)} - {props.total_memory / 1e9:.1f} GB")
print()

from unsloth import FastLanguageModel

print("Chargement du modele Llama 3.2 3B Instruct (4-bit)...")
print("   Cela peut prendre 2-3 minutes sur Kaggle...\n")

model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/Llama-3.2-3B-Instruct-bnb-4bit",
    max_seq_length=2048,
    load_in_4bit=True,
    use_gradient_checkpointing="unsloth",
)

print(f"Modele Llama 3.2 3B charge !")
print(f"   VRAM GPU 0 : {torch.cuda.memory_allocated(0) / 1e9:.2f} GB")

model = FastLanguageModel.get_peft_model(
    model,
    r=16,
    target_modules=[
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj",
    ],
    lora_alpha=16,
    lora_dropout=0,
    bias="none",
    use_rslora=False,
    loftq_config=None,
)

trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
total = sum(p.numel() for p in model.parameters())
print(f"LoRA configure (rank=16, alpha=16)")
print(f"   Parametres entrainables : {trainable:,}")
print(f"   Parametres totaux : {total:,}")


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  CELLULE 3 : Chargement et preparation du dataset                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ============================================================
# MODIFIEZ CE CHEMIN selon votre Dataset Kaggle
# ============================================================
KAGGLE_DATASET_PATH = "/kaggle/input/datasets/borgirayen/medaichain-dataset"
DATASET_FILE = os.path.join(KAGGLE_DATASET_PATH, "medical_dataset.jsonl")

if not os.path.exists(DATASET_FILE):
    print(f"ERREUR : Fichier '{DATASET_FILE}' introuvable !")
    print()
    print("Pour uploader votre dataset sur Kaggle :")
    print("   1. Allez sur kaggle.com/datasets/new")
    print("   2. Uploadez le fichier 'medical_dataset.jsonl'")
    print("   3. Donnez-lui le nom 'medaichain-dataset'")
    print("   4. Dans votre Notebook : Add Data > votre dataset")
    print("   5. Relancez cette cellule")
    print()
    print("Contenu de /kaggle/input/ :")
    if os.path.exists("/kaggle/input/"):
        for item in os.listdir("/kaggle/input/"):
            print(f"   {item}")
    raise FileNotFoundError(DATASET_FILE)

SYSTEM_PROMPT = """Tu es MedAIChain, un expert medical IA specialise dans l'analyse de rapports medicaux (analyses de sang, bilans biologiques, radiographies).

Tu dois renvoyer une reponse structuree en JSON (en francais) avec EXACTEMENT ces champs :
- "diagnosis" : Un resume clair du diagnostic base sur l'analyse.
- "advice" : Des conseils hygieno-dietetiques personnalises.
- "prescription_suggestions" : Une liste d'objets { "name", "dosage", "frequency", "duration" } pour les medicaments. Liste vide [] si aucun medicament n'est necessaire.
- "emergency_level" : "faible", "moyen" ou "critique".
- "confidence" : Un nombre decimal entre 0.0 et 1.0 (ex: 0.85).
- "sources" : Un tableau de references medicales (ex: ["Guidelines WHO"]).

Reponds UNIQUEMENT en JSON valide, sans texte supplementaire."""


def extract_medical_text(gpt_response_str):
    """Extrait les valeurs medicales de la reponse GPT pour creer
    un texte d'entree similaire a ce que l'OCR produirait."""
    try:
        resp = json.loads(gpt_response_str)
        diagnosis = resp.get("diagnosis", "")

        if "Parametres anormaux" in diagnosis or "Paramètres anormaux" in diagnosis:
            sep = "Paramètres anormaux" if "Paramètres anormaux" in diagnosis else "Parametres anormaux"
            parts = diagnosis.split(sep)
            params_text = parts[1].lstrip(" :").strip().rstrip(".")
            param_items = [p.strip() for p in params_text.split(";") if p.strip()]

            lines = ["RESULTATS D'ANALYSE MEDICALE", "=" * 40, ""]
            for item in param_items:
                match = re.match(r"(.+?):\s*([\d.,]+)\s*(\S+)", item)
                if match:
                    name, value, unit = match.groups()
                    norm_match = re.search(r"norme:\s*([\d.,]+-[\d.,]+)", item)
                    norm = norm_match.group(1) if norm_match else ""
                    lines.append(f"  {name.strip()}: {value} {unit}   (ref: {norm})" if norm else f"  {name.strip()}: {value} {unit}")
                else:
                    lines.append(f"  {item}")
            return "\n".join(lines)
        else:
            return f"RESULTATS D'ANALYSE MEDICALE\n{'=' * 40}\n\n{diagnosis}"
    except Exception:
        return "RESULTATS D'ANALYSE MEDICALE\n\nAnalyse a interpreter."


raw_data = []
with open(DATASET_FILE, 'r', encoding='utf-8') as f:
    for line in f:
        if line.strip():
            raw_data.append(json.loads(line.strip()))

print(f"Dataset charge : {len(raw_data)} exemples")

training_conversations = []
for entry in raw_data:
    conversations = entry.get("conversations", [])
    if len(conversations) < 2:
        continue

    gpt_response = conversations[1]["value"]
    medical_text = extract_medical_text(gpt_response)

    user_message = (
        f"{medical_text}\n\n"
        "Analyse ces resultats et donne le diagnostic, les conseils et l'ordonnance. "
        "Reponds en JSON structure."
    )

    convo = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message},
        {"role": "assistant", "content": gpt_response},
    ]
    training_conversations.append({"conversations": convo})

print(f"Conversations d'entrainement preparees : {len(training_conversations)}")
print()
print("Apercu du 1er exemple :")
sample_convo = training_conversations[0]["conversations"]
print(f"   [USER] {sample_convo[1]['content'][:150]}...")
print(f"   [ASSISTANT] {sample_convo[2]['content'][:120]}...")


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  CELLULE 4 : Formatage pour l'entrainement Llama 3.2                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

from unsloth.chat_templates import get_chat_template
from datasets import Dataset as HFDataset

tokenizer = get_chat_template(
    tokenizer,
    chat_template="llama-3.1",
)

def formatting_func(examples):
    texts = []
    for convo in examples["conversations"]:
        text = tokenizer.apply_chat_template(
            convo, tokenize=False, add_generation_prompt=False
        )
        texts.append(text)
    return {"text": texts}

hf_dataset = HFDataset.from_list(training_conversations)
formatted_dataset = hf_dataset.map(formatting_func, batched=True)

print(f"Dataset formate : {len(formatted_dataset)} exemples")
print()
print("Extrait du 1er exemple formate :")
print(formatted_dataset[0]["text"][:400] + "...")

token_lengths = []
for example in formatted_dataset:
    tokens = tokenizer(example["text"], return_tensors="pt")
    token_lengths.append(tokens["input_ids"].shape[1])

print(f"\nStatistiques des tokens :")
print(f"   Min: {min(token_lengths)}, Max: {max(token_lengths)}, Moyenne: {sum(token_lengths)/len(token_lengths):.0f}")


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  CELLULE 5 : Entrainement avec SFTTrainer                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

from trl import SFTTrainer, SFTConfig

sft_config = SFTConfig(
    dataset_text_field="text",
    max_seq_length=2048,
    packing=False,
    per_device_train_batch_size=2,
    gradient_accumulation_steps=4,
    warmup_steps=10,
    max_steps=300,
    learning_rate=2e-4,
    fp16=True,
    bf16=False,
    logging_steps=5,
    output_dir="/kaggle/working/outputs",
    save_steps=50,
    save_total_limit=2,
    weight_decay=0.01,
    lr_scheduler_type="cosine",
    optim="adamw_8bit",
    seed=42,
    report_to="none",
    dataloader_num_workers=2,
    num_train_epochs=6,
)

trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=formatted_dataset,
    args=sft_config,
)

print("Configuration de l'entrainement :")
print(f"   Modele : Llama 3.2 3B Instruct (4-bit LoRA)")
print(f"   Batch size effectif : {2 * 4}")
print(f"   Steps max : 300")
print(f"   Learning rate : 2e-4")
print(f"   Precision : fp16")
print()

for i in range(torch.cuda.device_count()):
    allocated = torch.cuda.memory_allocated(i) / 1e9
    total = torch.cuda.get_device_properties(i).total_memory / 1e9
    print(f"   GPU {i} VRAM : {allocated:.1f}GB / {total:.1f}GB")

print()
print("Lancement de l'entrainement...")
print("   (Estime : 10-20 min pour 300 steps sur T4)")
print()

results = trainer.train()

print()
print("=" * 70)
print("ENTRAINEMENT TERMINE !")
print(f"   Loss finale : {results.training_loss:.4f}")
print(f"   Duree : {results.metrics['train_runtime']:.0f} secondes")
print("=" * 70)


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  CELLULE 6 : Test du modele fine-tune                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

print("Test du modele fine-tune...\n")

FastLanguageModel.for_inference(model)

test_messages = [
    {"role": "system", "content": SYSTEM_PROMPT},
    {"role": "user", "content": """RESULTATS D'ANALYSE MEDICALE
========================================

  Hemoglobine: 8.5 g/dL   (ref: 12-17.5)
  Globules Rouges: 3.2 T/L   (ref: 4-5.5)
  VGM: 72 fL   (ref: 80-100)
  Fer serique: 25 ug/dL   (ref: 60-170)

Analyse ces resultats et donne le diagnostic, les conseils et l'ordonnance. Reponds en JSON structure."""},
]

inputs = tokenizer.apply_chat_template(
    test_messages,
    tokenize=True,
    add_generation_prompt=True,
    return_tensors="pt",
).to("cuda")

with torch.no_grad():
    outputs = model.generate(
        input_ids=inputs,
        max_new_tokens=512,
        temperature=0.3,
        do_sample=True,
    )

response = tokenizer.decode(outputs[0][inputs.shape[-1]:], skip_special_tokens=True)

print("Reponse du modele :")
print(response[:600])

try:
    parsed = json.loads(response)
    print("\nJSON valide !")
    print(f"   Diagnostic : {parsed.get('diagnosis', 'N/A')[:100]}...")
    print(f"   Urgence : {parsed.get('emergency_level', 'N/A')}")
    if parsed.get('prescription_suggestions'):
        for rx in parsed['prescription_suggestions']:
            print(f"   Rx : {rx.get('name', '?')} - {rx.get('dosage', '?')}")
except json.JSONDecodeError:
    print("\nLa reponse n'est pas du JSON parfait (normal si peu de steps)")
    print("Le format JSON sera force par llama-server via response_format")


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  CELLULE 7 : Export en GGUF (pour llama-server, SANS Ollama)               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

GGUF_OUTPUT = "/kaggle/working/medaichain_gguf"
MODEL_FILENAME = "medaichain-medical-3B-Q4_K_M.gguf"

print("Exportation du modele en format GGUF...")
print("   Quantization : Q4_K_M (bon compromis qualite/taille)")
print("   Ceci peut prendre 10-15 minutes, soyez patient\n")

try:
    model.save_pretrained_gguf(
        GGUF_OUTPUT,
        tokenizer,
        quantization_method="q4_k_m",
    )
    print("Export GGUF reussi !")
except Exception as e:
    print(f"Erreur export natif : {e}")
    print("Tentative via merged + llama.cpp...\n")

    MERGED_OUTPUT = "/kaggle/working/medaichain_merged"
    model.save_pretrained_merged(MERGED_OUTPUT, tokenizer, save_method="merged_16bit")

    !pip install -q llama-cpp-python 2>/dev/null
    !git clone -q https://github.com/ggerganov/llama.cpp /kaggle/working/llama_cpp 2>/dev/null
    !cd /kaggle/working/llama_cpp && pip install -q -r requirements.txt 2>/dev/null
    !python /kaggle/working/llama_cpp/convert_hf_to_gguf.py {MERGED_OUTPUT} \
        --outfile {GGUF_OUTPUT}/{MODEL_FILENAME} --outtype q4_k_m

    print("Conversion GGUF terminee (methode llama.cpp)")

print()
print("Fichiers generes :")
if os.path.exists(GGUF_OUTPUT):
    for f in os.listdir(GGUF_OUTPUT):
        size = os.path.getsize(os.path.join(GGUF_OUTPUT, f))
        print(f"   {f} ({size / 1e6:.1f} MB)")


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  CELLULE 8 : Renommer le GGUF et compresser pour telechargement            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

import shutil
import glob

gguf_files = glob.glob(os.path.join(GGUF_OUTPUT, "*.gguf"))
if gguf_files:
    src = gguf_files[0]
    dst = os.path.join(GGUF_OUTPUT, MODEL_FILENAME)
    if src != dst:
        shutil.move(src, dst)
        print(f"Renomme : {os.path.basename(src)} -> {MODEL_FILENAME}")

    file_size = os.path.getsize(dst) / 1e9
    print(f"Taille du modele : {file_size:.2f} GB")
else:
    print("ERREUR : Aucun fichier .gguf trouve !")

ARCHIVE_NAME = "/kaggle/working/medaichain_model"
print("\nCompression...")
shutil.make_archive(ARCHIVE_NAME, 'zip', GGUF_OUTPUT)
archive_size = os.path.getsize(f"{ARCHIVE_NAME}.zip") / 1e9
print(f"Archive creee : {ARCHIVE_NAME}.zip ({archive_size:.2f} GB)")

print()
print("=" * 70)
print("TELECHARGEMENT")
print("=" * 70)
print()
print("   Le fichier .zip est dans /kaggle/working/")
print("   Panneau de droite > Output > Download")
print()
print("=" * 70)
print("INSTALLATION SUR VOTRE PC (SANS Ollama)")
print("=" * 70)
print()
print("   1. Decompressez 'medaichain_model.zip'")
print(f"   2. Copiez '{MODEL_FILENAME}' dans :")
print("      medaichain-backend/models/")
print()
print("   3. Telechargez llama-server (une seule fois) :")
print("      cd medaichain-backend")
print("      python download_engine.py")
print()
print("   4. Lancez le serveur IA :")
print("      start_ai_server.bat")
print()
print("   5. Lancez le backend NestJS :")
print("      npm run start:dev")
print()
print("   Le modele tourne en LOCAL, pas besoin d'Ollama !")
print("=" * 70)
