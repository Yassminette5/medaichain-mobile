"""
Générateur de Dataset Synthétique Médical pour MEDAIChain
=========================================================
Génère des images simulant des rapports médicaux (analyses de sang, bilans)
avec les réponses IA structurées correspondantes (diagnostic, conseils, ordonnance).

Usage:
    pip install Pillow
    python generate_synthetic_dataset.py
"""

import json
import os
import random
from PIL import Image, ImageDraw, ImageFont

# ─── Configuration ───────────────────────────────────────────────────────────
DATASET_DIR = './dataset'
OUTPUT_JSONL = 'medical_dataset.jsonl'
NUM_SAMPLES = 50

# ─── Données Synthétiques Médicales ──────────────────────────────────────────

BLOOD_TESTS = [
    {
        "type": "Numération Formule Sanguine (NFS)",
        "params": [
            {"name": "Globules Rouges (GR)", "unit": "T/L", "normal_range": (4.0, 5.5),
             "abnormal_low": (2.5, 3.9), "abnormal_high": (5.6, 7.0)},
            {"name": "Hémoglobine (Hb)", "unit": "g/dL", "normal_range": (12.0, 17.5),
             "abnormal_low": (7.0, 11.9), "abnormal_high": (17.6, 22.0)},
            {"name": "Hématocrite (Ht)", "unit": "%", "normal_range": (36.0, 50.0),
             "abnormal_low": (20.0, 35.9), "abnormal_high": (50.1, 60.0)},
            {"name": "Globules Blancs (GB)", "unit": "G/L", "normal_range": (4.0, 10.0),
             "abnormal_low": (1.5, 3.9), "abnormal_high": (10.1, 25.0)},
            {"name": "Plaquettes", "unit": "G/L", "normal_range": (150, 400),
             "abnormal_low": (50, 149), "abnormal_high": (401, 700)},
            {"name": "VGM", "unit": "fL", "normal_range": (80, 100),
             "abnormal_low": (60, 79), "abnormal_high": (101, 120)},
        ]
    },
    {
        "type": "Bilan Lipidique",
        "params": [
            {"name": "Cholestérol Total", "unit": "g/L", "normal_range": (1.5, 2.0),
             "abnormal_low": (0.8, 1.49), "abnormal_high": (2.01, 3.5)},
            {"name": "HDL Cholestérol", "unit": "g/L", "normal_range": (0.4, 0.6),
             "abnormal_low": (0.15, 0.39), "abnormal_high": (0.61, 1.0)},
            {"name": "LDL Cholestérol", "unit": "g/L", "normal_range": (0.7, 1.6),
             "abnormal_low": (0.3, 0.69), "abnormal_high": (1.61, 2.5)},
            {"name": "Triglycérides", "unit": "g/L", "normal_range": (0.5, 1.5),
             "abnormal_low": (0.2, 0.49), "abnormal_high": (1.51, 4.0)},
        ]
    },
    {
        "type": "Bilan Hépatique",
        "params": [
            {"name": "ASAT (TGO)", "unit": "UI/L", "normal_range": (10, 40),
             "abnormal_low": (2, 9), "abnormal_high": (41, 200)},
            {"name": "ALAT (TGP)", "unit": "UI/L", "normal_range": (7, 56),
             "abnormal_low": (1, 6), "abnormal_high": (57, 300)},
            {"name": "GGT", "unit": "UI/L", "normal_range": (9, 48),
             "abnormal_low": (2, 8), "abnormal_high": (49, 250)},
            {"name": "Bilirubine Totale", "unit": "mg/L", "normal_range": (3, 10),
             "abnormal_low": (1, 2), "abnormal_high": (11, 40)},
            {"name": "Phosphatases Alcalines", "unit": "UI/L", "normal_range": (44, 147),
             "abnormal_low": (20, 43), "abnormal_high": (148, 400)},
        ]
    },
    {
        "type": "Bilan Rénal",
        "params": [
            {"name": "Créatinine", "unit": "mg/L", "normal_range": (6, 12),
             "abnormal_low": (2, 5), "abnormal_high": (13, 40)},
            {"name": "Urée", "unit": "g/L", "normal_range": (0.15, 0.45),
             "abnormal_low": (0.05, 0.14), "abnormal_high": (0.46, 1.5)},
            {"name": "Acide Urique", "unit": "mg/L", "normal_range": (25, 70),
             "abnormal_low": (10, 24), "abnormal_high": (71, 120)},
            {"name": "DFG estimé", "unit": "mL/min", "normal_range": (90, 120),
             "abnormal_low": (30, 89), "abnormal_high": (121, 150)},
        ]
    },
    {
        "type": "Glycémie et Diabète",
        "params": [
            {"name": "Glycémie à jeun", "unit": "g/L", "normal_range": (0.70, 1.10),
             "abnormal_low": (0.40, 0.69), "abnormal_high": (1.11, 3.0)},
            {"name": "HbA1c", "unit": "%", "normal_range": (4.0, 5.6),
             "abnormal_low": (3.0, 3.9), "abnormal_high": (5.7, 12.0)},
            {"name": "Insuline", "unit": "µUI/mL", "normal_range": (2.6, 24.9),
             "abnormal_low": (0.5, 2.5), "abnormal_high": (25.0, 80.0)},
        ]
    },
    {
        "type": "Bilan Thyroïdien",
        "params": [
            {"name": "TSH", "unit": "mUI/L", "normal_range": (0.27, 4.2),
             "abnormal_low": (0.01, 0.26), "abnormal_high": (4.3, 20.0)},
            {"name": "T4 Libre", "unit": "pmol/L", "normal_range": (12.0, 22.0),
             "abnormal_low": (5.0, 11.9), "abnormal_high": (22.1, 40.0)},
            {"name": "T3 Libre", "unit": "pmol/L", "normal_range": (3.1, 6.8),
             "abnormal_low": (1.0, 3.0), "abnormal_high": (6.9, 15.0)},
        ]
    },
    {
        "type": "Bilan Inflammatoire",
        "params": [
            {"name": "CRP", "unit": "mg/L", "normal_range": (0, 5),
             "abnormal_low": (0, 0), "abnormal_high": (6, 200)},
            {"name": "VS (1ère heure)", "unit": "mm", "normal_range": (1, 15),
             "abnormal_low": (0, 0), "abnormal_high": (16, 100)},
            {"name": "Fibrinogène", "unit": "g/L", "normal_range": (2.0, 4.0),
             "abnormal_low": (0.5, 1.9), "abnormal_high": (4.1, 8.0)},
        ]
    },
]

# Diagnostics, conseils et prescriptions par type d'anomalie
MEDICAL_RESPONSES = {
    "Numération Formule Sanguine (NFS)": {
        "low": {
            "diagnosis": "Anémie détectée avec des valeurs basses de globules rouges et/ou d'hémoglobine. Possible carence en fer ou en vitamine B12.",
            "advice": "Augmenter la consommation d'aliments riches en fer (viande rouge, lentilles, épinards). Éviter le thé et le café pendant les repas. Repos recommandé en cas de fatigue importante.",
            "prescriptions": [
                {"name": "Fer (Tardyferon)", "dosage": "80 mg", "frequency": "1 comprimé par jour", "duration": "3 mois"},
                {"name": "Vitamine B12", "dosage": "1000 µg", "frequency": "1 injection/semaine", "duration": "1 mois"},
                {"name": "Acide Folique", "dosage": "5 mg", "frequency": "1 comprimé par jour", "duration": "3 mois"},
            ],
            "emergency_level": "moyen"
        },
        "high": {
            "diagnosis": "Polyglobulie ou leucocytose détectée. Valeurs élevées des éléments sanguins pouvant indiquer une infection, une inflammation ou un trouble hématologique.",
            "advice": "Hydratation abondante (2L d'eau/jour minimum). Consulter un hématologue si les valeurs persistent. Éviter les efforts physiques intenses.",
            "prescriptions": [
                {"name": "Aspégic", "dosage": "100 mg", "frequency": "1 sachet par jour", "duration": "15 jours"},
            ],
            "emergency_level": "moyen"
        },
        "normal": {
            "diagnosis": "Bilan sanguin dans les normes. Aucune anomalie détectée sur la numération formule sanguine.",
            "advice": "Maintenir une alimentation équilibrée et variée. Activité physique régulière recommandée (30 min/jour). Contrôle de routine dans 1 an.",
            "prescriptions": [],
            "emergency_level": "faible"
        }
    },
    "Bilan Lipidique": {
        "low": {
            "diagnosis": "Hypocholestérolémie ou taux de HDL bas. Risque cardiovasculaire accru lié à un profil lipidique défavorable.",
            "advice": "Consommer des acides gras oméga-3 (poisson gras, noix). Éviter les graisses saturées et les aliments ultra-transformés. Activité physique régulière.",
            "prescriptions": [
                {"name": "Oméga-3 (Maxepa)", "dosage": "1000 mg", "frequency": "2 capsules par jour", "duration": "3 mois"},
            ],
            "emergency_level": "faible"
        },
        "high": {
            "diagnosis": "Hypercholestérolémie et/ou hypertriglycéridémie détectée. Risque cardiovasculaire augmenté nécessitant une prise en charge.",
            "advice": "Régime pauvre en graisses saturées. Augmenter les fibres (fruits, légumes, avoine). Exercice physique 5 fois/semaine pendant 30 min. Arrêt du tabac si applicable.",
            "prescriptions": [
                {"name": "Atorvastatine", "dosage": "20 mg", "frequency": "1 comprimé le soir", "duration": "6 mois"},
                {"name": "Fénofibrate", "dosage": "160 mg", "frequency": "1 comprimé par jour", "duration": "3 mois"},
            ],
            "emergency_level": "moyen"
        },
        "normal": {
            "diagnosis": "Bilan lipidique normal. Pas de dyslipidémie détectée.",
            "advice": "Continuer un mode de vie sain. Limiter les aliments riches en graisses saturées. Contrôle annuel recommandé.",
            "prescriptions": [],
            "emergency_level": "faible"
        }
    },
    "Bilan Hépatique": {
        "low": {
            "diagnosis": "Valeurs hépatiques légèrement basses, généralement sans signification pathologique majeure.",
            "advice": "Alimentation équilibrée. Éviter l'alcool et les médicaments hépatotoxiques. Consulter en cas de symptômes digestifs persistants.",
            "prescriptions": [],
            "emergency_level": "faible"
        },
        "high": {
            "diagnosis": "Cytolyse hépatique détectée avec élévation des transaminases (ASAT/ALAT). Possible atteinte hépatique d'origine médicamenteuse, virale ou alcoolique.",
            "advice": "Arrêt immédiat de l'alcool. Éviter les médicaments hépatotoxiques (paracétamol en excès). Régime léger sans graisses. Hydratation importante.",
            "prescriptions": [
                {"name": "Desmodium (Hépatoprotecteur)", "dosage": "200 mg", "frequency": "3 gélules par jour", "duration": "1 mois"},
                {"name": "Silymarine (Légalon)", "dosage": "140 mg", "frequency": "1 comprimé 3 fois/jour", "duration": "2 mois"},
            ],
            "emergency_level": "critique"
        },
        "normal": {
            "diagnosis": "Fonction hépatique normale. Aucune anomalie des enzymes hépatiques.",
            "advice": "Maintenir une consommation d'alcool modérée. Alimentation riche en légumes et fruits. Éviter l'automédication excessive.",
            "prescriptions": [],
            "emergency_level": "faible"
        }
    },
    "Bilan Rénal": {
        "low": {
            "diagnosis": "Fonction rénale potentiellement altérée avec DFG diminué. Possible insuffisance rénale débutante.",
            "advice": "Hydratation régulière (1.5 à 2L/jour). Réduire la consommation de sel et de protéines animales. Éviter les anti-inflammatoires (AINS). Contrôle rapproché recommandé.",
            "prescriptions": [
                {"name": "Bicarbonate de Sodium", "dosage": "500 mg", "frequency": "2 gélules par jour", "duration": "1 mois"},
            ],
            "emergency_level": "moyen"
        },
        "high": {
            "diagnosis": "Élévation de la créatinine et de l'urée. Surcharge rénale détectée. Possible déshydratation ou atteinte rénale.",
            "advice": "Hydratation intensive. Régime hypoprotéique. Arrêt des médicaments néphrotoxiques. Consultation néphrologique urgente recommandée.",
            "prescriptions": [
                {"name": "Kayexalate", "dosage": "15 g", "frequency": "1 sachet 3 fois/jour", "duration": "5 jours"},
            ],
            "emergency_level": "critique"
        },
        "normal": {
            "diagnosis": "Fonction rénale normale. Créatinine et urée dans les valeurs normales.",
            "advice": "Boire au moins 1.5L d'eau par jour. Limiter le sel. Éviter les AINS au long cours.",
            "prescriptions": [],
            "emergency_level": "faible"
        }
    },
    "Glycémie et Diabète": {
        "low": {
            "diagnosis": "Hypoglycémie détectée. Glycémie à jeun inférieure aux normes. Risque de malaise hypoglycémique.",
            "advice": "Fractionner les repas (5 à 6 petits repas/jour). Toujours avoir du sucre rapide sur soi. Éviter les jeûnes prolongés.",
            "prescriptions": [
                {"name": "Glucose oral", "dosage": "15 g", "frequency": "En cas de malaise", "duration": "À vie"},
            ],
            "emergency_level": "moyen"
        },
        "high": {
            "diagnosis": "Hyperglycémie et/ou HbA1c élevée. Diabète de type 2 suspecté ou mal équilibré. Prise en charge diététique et médicamenteuse nécessaire.",
            "advice": "Régime hypoglucidique strict. Supprimer les sucres rapides et les sodas. Exercice physique quotidien (marche 30 min). Surveillance glycémique régulière.",
            "prescriptions": [
                {"name": "Metformine", "dosage": "850 mg", "frequency": "1 comprimé matin et soir", "duration": "6 mois"},
                {"name": "Gliclazide", "dosage": "30 mg", "frequency": "1 comprimé le matin", "duration": "3 mois"},
            ],
            "emergency_level": "moyen"
        },
        "normal": {
            "diagnosis": "Glycémie à jeun et HbA1c dans les normes. Pas de diabète détecté.",
            "advice": "Maintenir un poids santé. Limiter les sucres ajoutés. Activité physique régulière.",
            "prescriptions": [],
            "emergency_level": "faible"
        }
    },
    "Bilan Thyroïdien": {
        "low": {
            "diagnosis": "Hypothyroïdie détectée avec TSH élevée et T4/T3 basses. Ralentissement du métabolisme possible.",
            "advice": "Prendre le traitement thyroïdien le matin à jeun, 30 min avant le petit-déjeuner. Éviter le soja et le chou en excès. Contrôle TSH dans 6 semaines.",
            "prescriptions": [
                {"name": "Lévothyroxine (Levothyrox)", "dosage": "50 µg", "frequency": "1 comprimé le matin à jeun", "duration": "À réévaluer dans 6 semaines"},
            ],
            "emergency_level": "moyen"
        },
        "high": {
            "diagnosis": "Hyperthyroïdie suspectée avec TSH basse et T4/T3 élevées. Hyperactivité thyroïdienne nécessitant un bilan complet.",
            "advice": "Éviter les excitants (café, thé). Repos en cas de palpitations. Consultation endocrinologue recommandée. Éviter les sources d'iode en excès.",
            "prescriptions": [
                {"name": "Carbimazole (Néo-Mercazole)", "dosage": "20 mg", "frequency": "1 comprimé par jour", "duration": "1 mois puis réévaluation"},
                {"name": "Propranolol", "dosage": "40 mg", "frequency": "1 comprimé 2 fois/jour", "duration": "15 jours"},
            ],
            "emergency_level": "moyen"
        },
        "normal": {
            "diagnosis": "Bilan thyroïdien normal. Fonction thyroïdienne correcte.",
            "advice": "Aucune mesure particulière. Consommation modérée d'iode. Contrôle dans 1 an si symptômes.",
            "prescriptions": [],
            "emergency_level": "faible"
        }
    },
    "Bilan Inflammatoire": {
        "low": {
            "diagnosis": "Marqueurs inflammatoires dans les normes basses. Aucun signe d'inflammation systémique.",
            "advice": "Aucune mesure particulière nécessaire. Maintenir un mode de vie sain.",
            "prescriptions": [],
            "emergency_level": "faible"
        },
        "high": {
            "diagnosis": "Syndrome inflammatoire biologique détecté (CRP et/ou VS élevées). Possible infection, inflammation chronique ou pathologie auto-immune.",
            "advice": "Repos relatif. Hydratation abondante. Surveiller la température. Consulter si fièvre persistante ou douleurs articulaires.",
            "prescriptions": [
                {"name": "Paracétamol", "dosage": "1000 mg", "frequency": "1 comprimé 3 fois/jour", "duration": "5 jours"},
                {"name": "Ibuprofène", "dosage": "400 mg", "frequency": "1 comprimé 2 fois/jour au repas", "duration": "5 jours"},
            ],
            "emergency_level": "moyen"
        },
        "normal": {
            "diagnosis": "Aucun syndrome inflammatoire détecté. CRP et VS normales.",
            "advice": "Mode de vie sain. Anti-inflammatoires naturels (curcuma, oméga-3) en prévention.",
            "prescriptions": [],
            "emergency_level": "faible"
        }
    },
}

PATIENT_NAMES = [
    "Mohamed Ben Ali", "Fatma Trabelsi", "Ahmed Gharbi", "Salma Bouzid",
    "Youssef Hamdi", "Amira Chaari", "Karim Mansour", "Nour Jelassi",
    "Omar Belhadj", "Sana Mrad", "Amine Sfar", "Ines Bouaziz",
    "Mehdi Kallel", "Rania Dridi", "Bilel Jemaa", "Mariam Haddad",
    "Sami Riahi", "Leila Oueslati", "Hichem Zouari", "Cyrine Mahjoub",
    "Ali Sassi", "Hajer Ben Salem", "Wael Ferchichi", "Asma Souissi",
    "Tarek Maamouri", "Rahma Khelifi", "Zied Chouchane", "Emna Ben Amor",
]

LABS = [
    "Laboratoire Central Tunis", "Labo BioMed Sousse", "Centre d'Analyses Sfax",
    "Laboratoire Pasteur Ariana", "BioLab Monastir", "Labo El Manar",
    "Centre Médical Ben Arous", "Laboratoire Avicenne Nabeul",
]

DOCTORS = [
    "Dr. Kamel Bouazizi", "Dr. Sonia Gharbi", "Dr. Mourad Trabelsi",
    "Dr. Leila Ben Ahmed", "Dr. Farid Hamdi", "Dr. Amina Khelifi",
]


def generate_value(param, status):
    """Génère une valeur pour un paramètre selon le statut voulu."""
    if status == "normal":
        low, high = param["normal_range"]
    elif status == "low":
        low, high = param["abnormal_low"]
    else:
        low, high = param["abnormal_high"]

    if isinstance(low, int) and isinstance(high, int):
        return random.randint(low, high)
    else:
        return round(random.uniform(low, high), 2)


def create_report_image(sample_id, test_data, patient_name, lab_name, doctor, date_str):
    """Crée une image simulant un rapport médical d'analyses."""
    width, height = 800, 1000
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)

    # Essayer de charger une police, sinon utiliser la police par défaut
    try:
        font_title = ImageFont.truetype("arial.ttf", 24)
        font_header = ImageFont.truetype("arial.ttf", 18)
        font_normal = ImageFont.truetype("arial.ttf", 14)
        font_small = ImageFont.truetype("arial.ttf", 11)
    except (IOError, OSError):
        font_title = ImageFont.load_default()
        font_header = font_title
        font_normal = font_title
        font_small = font_title

    y = 20

    # En-tête du labo
    draw.rectangle([0, 0, width, 80], fill='#1a5276')
    draw.text((20, 15), lab_name.upper(), fill='white', font=font_title)
    draw.text((20, 50), "Compte Rendu d'Analyses Médicales", fill='#d4e6f1', font=font_small)
    y = 95

    # Infos patient
    draw.rectangle([15, y, width - 15, y + 80], outline='#2c3e50', width=1)
    draw.text((25, y + 5), f"Patient : {patient_name}", fill='#2c3e50', font=font_normal)
    draw.text((25, y + 25), f"Date : {date_str}", fill='#2c3e50', font=font_normal)
    draw.text((400, y + 5), f"Médecin prescripteur : {doctor}", fill='#2c3e50', font=font_small)
    draw.text((400, y + 25), f"N° Dossier : {sample_id}", fill='#2c3e50', font=font_small)
    y += 95

    # Type d'analyse
    draw.rectangle([15, y, width - 15, y + 35], fill='#2980b9')
    draw.text((25, y + 8), test_data["type"], fill='white', font=font_header)
    y += 50

    # En-têtes du tableau
    draw.rectangle([15, y, width - 15, y + 25], fill='#d6eaf8')
    draw.text((25, y + 5), "Paramètre", fill='#2c3e50', font=font_normal)
    draw.text((350, y + 5), "Résultat", fill='#2c3e50', font=font_normal)
    draw.text((470, y + 5), "Unité", fill='#2c3e50', font=font_normal)
    draw.text((570, y + 5), "Valeurs Normales", fill='#2c3e50', font=font_normal)
    y += 30

    # Lignes de résultats
    for i, param in enumerate(test_data["params"]):
        bg_color = '#f8f9fa' if i % 2 == 0 else 'white'
        draw.rectangle([15, y, width - 15, y + 28], fill=bg_color)

        value = param["_value"]
        normal_low, normal_high = param["normal_range"]

        # Couleur du résultat : rouge si hors norme
        is_normal = normal_low <= value <= normal_high
        val_color = '#27ae60' if is_normal else '#e74c3c'

        # Indicateur d'anomalie
        flag = "" if is_normal else (" ▼" if value < normal_low else " ▲")

        draw.text((25, y + 5), param["name"], fill='#2c3e50', font=font_normal)
        draw.text((350, y + 5), f"{value}{flag}", fill=val_color, font=font_normal)
        draw.text((470, y + 5), param["unit"], fill='#7f8c8d', font=font_normal)
        draw.text((570, y + 5), f"{normal_low} - {normal_high}", fill='#7f8c8d', font=font_normal)
        y += 30

    # Ligne de séparation
    y += 15
    draw.line([15, y, width - 15, y], fill='#bdc3c7', width=1)
    y += 15

    # Notes
    draw.text((25, y), "Note : Les valeurs hors normes sont signalées en rouge.", fill='#95a5a6', font=font_small)
    y += 20
    draw.text((25, y), "Ce document est un rapport généré automatiquement.", fill='#95a5a6', font=font_small)

    # Pied de page
    draw.rectangle([0, height - 40, width, height], fill='#1a5276')
    draw.text((20, height - 30), f"© {lab_name} - Résultats confidentiels", fill='#d4e6f1', font=font_small)

    return img


def generate_ai_response(test_type, overall_status, test_data):
    """Génère une réponse IA structurée en JSON."""
    response_data = MEDICAL_RESPONSES[test_type][overall_status]

    # Ajouter détails spécifiques aux paramètres
    abnormal_params = []
    for p in test_data["params"]:
        low, high = p["normal_range"]
        if p["_value"] < low:
            abnormal_params.append(f"{p['name']}: {p['_value']} {p['unit']} (bas, norme: {low}-{high})")
        elif p["_value"] > high:
            abnormal_params.append(f"{p['name']}: {p['_value']} {p['unit']} (élevé, norme: {low}-{high})")

    detail = ""
    if abnormal_params:
        detail = " Paramètres anormaux : " + "; ".join(abnormal_params) + "."

    return {
        "diagnosis": response_data["diagnosis"] + detail,
        "advice": response_data["advice"],
        "prescription_suggestions": response_data["prescriptions"],
        "emergency_level": response_data["emergency_level"]
    }


def main():
    os.makedirs(DATASET_DIR, exist_ok=True)

    dataset_entries = []
    dates = [
        f"{random.randint(1,28):02d}/{random.randint(1,12):02d}/2025"
        for _ in range(NUM_SAMPLES)
    ]

    print(f"🏥 Génération de {NUM_SAMPLES} rapports médicaux synthétiques...\n")

    for i in range(NUM_SAMPLES):
        sample_id = f"MED_{i:04d}"
        test_template = random.choice(BLOOD_TESTS)
        patient = random.choice(PATIENT_NAMES)
        lab = random.choice(LABS)
        doctor = random.choice(DOCTORS)
        date_str = dates[i]

        # Décider du statut global : 40% normal, 30% high, 30% low
        rand = random.random()
        if rand < 0.40:
            overall_status = "normal"
        elif rand < 0.70:
            overall_status = "high"
        else:
            overall_status = "low"

        # Générer les valeurs pour chaque paramètre
        test_data = {
            "type": test_template["type"],
            "params": []
        }

        for param in test_template["params"]:
            param_copy = dict(param)
            if overall_status == "normal":
                param_copy["_value"] = generate_value(param, "normal")
            else:
                # Certains paramètres sont anormaux, d'autres normaux
                if random.random() < 0.6:
                    param_copy["_value"] = generate_value(param, overall_status)
                else:
                    param_copy["_value"] = generate_value(param, "normal")
            test_data["params"].append(param_copy)

        # Créer l'image
        img = create_report_image(sample_id, test_data, patient, lab, doctor, date_str)
        img_path = os.path.join(DATASET_DIR, f"{sample_id}.jpg")
        img.save(img_path, quality=95)

        # Générer la réponse IA
        ai_response = generate_ai_response(test_data["type"], overall_status, test_data)
        ai_response_str = json.dumps(ai_response, ensure_ascii=False, indent=2)

        # Sauvegarder le texte
        txt_path = os.path.join(DATASET_DIR, f"{sample_id}.txt")
        with open(txt_path, 'w', encoding='utf-8') as f:
            f.write(ai_response_str)

        # Créer l'entrée JSONL pour l'entraînement
        entry = {
            "id": sample_id,
            "image": img_path,
            "conversations": [
                {
                    "from": "human",
                    "value": "<image>\nAnalyse cette analyse médicale et donne le diagnostic, les conseils et l'ordonnance. Réponds en JSON structuré."
                },
                {
                    "from": "gpt",
                    "value": ai_response_str
                }
            ]
        }
        dataset_entries.append(entry)

        status_icon = "✅" if overall_status == "normal" else ("⚠️" if overall_status != "low" else "🔻")
        print(f"  {status_icon} {sample_id} | {test_data['type']:40s} | {overall_status:6s} | {patient}")

    # Sauvegarder le JSONL
    jsonl_path = os.path.join('.', OUTPUT_JSONL)
    with open(jsonl_path, 'w', encoding='utf-8') as f:
        for entry in dataset_entries:
            f.write(json.dumps(entry, ensure_ascii=False) + '\n')

    print(f"\n{'='*60}")
    print(f"✅ Dataset généré avec succès !")
    print(f"   📁 Images : {DATASET_DIR}/ ({NUM_SAMPLES} fichiers .jpg)")
    print(f"   📄 Textes : {DATASET_DIR}/ ({NUM_SAMPLES} fichiers .txt)")
    print(f"   📋 JSONL  : {jsonl_path} ({NUM_SAMPLES} entrées)")
    print(f"{'='*60}")

    # Statistiques
    stats = {}
    for e in dataset_entries:
        resp = json.loads(e["conversations"][1]["value"])
        level = resp["emergency_level"]
        stats[level] = stats.get(level, 0) + 1

    print(f"\n📊 Répartition des niveaux d'urgence :")
    for level, count in sorted(stats.items()):
        print(f"   {level:10s} : {count} cas ({count/NUM_SAMPLES*100:.0f}%)")


if __name__ == "__main__":
    main()
