from unsloth import FastLlavaModel
import torch
from datasets import load_dataset
from transformers import TrainingArguments
from trl import SFTTrainer
import os

# 1. Configuration
model_name = "unsloth/llava-v1.5-7b-bnb-4bit" # Version optimisée 4-bit
dataset_file = "medical_dataset.jsonl"
output_dir = "medical_model_finetuned"

if not os.path.exists(dataset_file):
    print(f"❌ Erreur: Le fichier {dataset_file} est introuvable. Lancez d'abord prepare_dataset.py.")
    exit()

# 2. Chargement du modèle et du tokenizer
model, tokenizer = FastLlavaModel.from_pretrained(
    model_name = model_name,
    load_in_4bit = True, # Économise la VRAM
)

# 3. Préparation du modèle pour le Fine-Tuning (PEFT/LoRA)
model = FastLlavaModel.get_peft_model(
    model,
    r = 16, # Rang LoRA
    target_modules = ["q_proj", "k_proj", "v_proj", "o_proj",
                     "gate_proj", "up_proj", "down_proj"],
    lora_alpha = 16,
    lora_dropout = 0,
    bias = "none",
)

# 4. Chargement des données
dataset = load_dataset("json", data_files=dataset_file, split="train")

# 5. Configuration de l'entraînement
trainer = SFTTrainer(
    model = model,
    tokenizer = tokenizer,
    train_dataset = dataset,
    dataset_text_field = "conversations", # Dépend du format JSONL
    max_seq_length = 2048,
    args = TrainingArguments(
        per_device_train_batch_size = 2,
        gradient_accumulation_steps = 4,
        warmup_steps = 5,
        max_steps = 60, # Augmentez pour un meilleur résultat (ex: 500)
        learning_rate = 2e-4,
        fp16 = not torch.cuda.is_bf16_supported(),
        bf16 = torch.cuda.is_bf16_supported(),
        logging_steps = 1,
        optim = "adamw_8bit",
        weight_decay = 0.01,
        lr_scheduler_type = "linear",
        seed = 3407,
        output_dir = output_dir,
    ),
)

# 6. Lancement de l'entraînement
print("🚀 Lancement de l'entraînement...")
trainer.train()

# 7. Sauvegarde du modèle
print(f"✅ Entraînement terminé. Sauvegarde dans {output_dir}")
model.save_pretrained(output_dir)
tokenizer.save_pretrained(output_dir)

# 8. Optionnel: Conversion en GGUF pour Ollama
# model.save_pretrained_gguf("medical_model_gguf", tokenizer, quantization_method = "q4_k_m")
