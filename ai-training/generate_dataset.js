/**
 * Générateur de Dataset Synthétique Médical pour MEDAIChain
 * =========================================================
 * Génère des images simulant des rapports médicaux (analyses de sang, bilans)
 * avec les réponses IA structurées correspondantes (diagnostic, conseils, ordonnance).
 *
 * Usage: node generate_dataset.js
 */

const { createCanvas } = require('canvas');
const fs = require('fs');
const path = require('path');

// ─── Configuration ───────────────────────────────────────────────────────────
const DATASET_DIR = './dataset';
const OUTPUT_JSONL = 'medical_dataset.jsonl';
const NUM_SAMPLES = 50;

// ─── Données Médicales ──────────────────────────────────────────────────────

const BLOOD_TESTS = [
  {
    type: "Numération Formule Sanguine (NFS)",
    params: [
      { name: "Globules Rouges (GR)", unit: "T/L", normal: [4.0, 5.5], low: [2.5, 3.9], high: [5.6, 7.0] },
      { name: "Hémoglobine (Hb)", unit: "g/dL", normal: [12.0, 17.5], low: [7.0, 11.9], high: [17.6, 22.0] },
      { name: "Hématocrite (Ht)", unit: "%", normal: [36.0, 50.0], low: [20.0, 35.9], high: [50.1, 60.0] },
      { name: "Globules Blancs (GB)", unit: "G/L", normal: [4.0, 10.0], low: [1.5, 3.9], high: [10.1, 25.0] },
      { name: "Plaquettes", unit: "G/L", normal: [150, 400], low: [50, 149], high: [401, 700] },
      { name: "VGM", unit: "fL", normal: [80, 100], low: [60, 79], high: [101, 120] },
    ]
  },
  {
    type: "Bilan Lipidique",
    params: [
      { name: "Cholestérol Total", unit: "g/L", normal: [1.5, 2.0], low: [0.8, 1.49], high: [2.01, 3.5] },
      { name: "HDL Cholestérol", unit: "g/L", normal: [0.4, 0.6], low: [0.15, 0.39], high: [0.61, 1.0] },
      { name: "LDL Cholestérol", unit: "g/L", normal: [0.7, 1.6], low: [0.3, 0.69], high: [1.61, 2.5] },
      { name: "Triglycérides", unit: "g/L", normal: [0.5, 1.5], low: [0.2, 0.49], high: [1.51, 4.0] },
    ]
  },
  {
    type: "Bilan Hépatique",
    params: [
      { name: "ASAT (TGO)", unit: "UI/L", normal: [10, 40], low: [2, 9], high: [41, 200] },
      { name: "ALAT (TGP)", unit: "UI/L", normal: [7, 56], low: [1, 6], high: [57, 300] },
      { name: "GGT", unit: "UI/L", normal: [9, 48], low: [2, 8], high: [49, 250] },
      { name: "Bilirubine Totale", unit: "mg/L", normal: [3, 10], low: [1, 2], high: [11, 40] },
      { name: "Phosphatases Alcalines", unit: "UI/L", normal: [44, 147], low: [20, 43], high: [148, 400] },
    ]
  },
  {
    type: "Bilan Rénal",
    params: [
      { name: "Créatinine", unit: "mg/L", normal: [6, 12], low: [2, 5], high: [13, 40] },
      { name: "Urée", unit: "g/L", normal: [0.15, 0.45], low: [0.05, 0.14], high: [0.46, 1.5] },
      { name: "Acide Urique", unit: "mg/L", normal: [25, 70], low: [10, 24], high: [71, 120] },
      { name: "DFG estimé", unit: "mL/min", normal: [90, 120], low: [30, 89], high: [121, 150] },
    ]
  },
  {
    type: "Glycémie et Diabète",
    params: [
      { name: "Glycémie à jeun", unit: "g/L", normal: [0.70, 1.10], low: [0.40, 0.69], high: [1.11, 3.0] },
      { name: "HbA1c", unit: "%", normal: [4.0, 5.6], low: [3.0, 3.9], high: [5.7, 12.0] },
      { name: "Insuline", unit: "µUI/mL", normal: [2.6, 24.9], low: [0.5, 2.5], high: [25.0, 80.0] },
    ]
  },
  {
    type: "Bilan Thyroïdien",
    params: [
      { name: "TSH", unit: "mUI/L", normal: [0.27, 4.2], low: [0.01, 0.26], high: [4.3, 20.0] },
      { name: "T4 Libre", unit: "pmol/L", normal: [12.0, 22.0], low: [5.0, 11.9], high: [22.1, 40.0] },
      { name: "T3 Libre", unit: "pmol/L", normal: [3.1, 6.8], low: [1.0, 3.0], high: [6.9, 15.0] },
    ]
  },
  {
    type: "Bilan Inflammatoire",
    params: [
      { name: "CRP", unit: "mg/L", normal: [0, 5], low: [0, 0], high: [6, 200] },
      { name: "VS (1ère heure)", unit: "mm", normal: [1, 15], low: [0, 0], high: [16, 100] },
      { name: "Fibrinogène", unit: "g/L", normal: [2.0, 4.0], low: [0.5, 1.9], high: [4.1, 8.0] },
    ]
  },
];

const RESPONSES = {
  "Numération Formule Sanguine (NFS)": {
    low: {
      diagnosis: "Anémie détectée avec des valeurs basses de globules rouges et/ou d'hémoglobine. Possible carence en fer ou en vitamine B12.",
      advice: "Augmenter la consommation d'aliments riches en fer (viande rouge, lentilles, épinards). Éviter le thé et le café pendant les repas. Repos recommandé en cas de fatigue importante.",
      prescriptions: [
        { name: "Fer (Tardyferon)", dosage: "80 mg", frequency: "1 comprimé par jour", duration: "3 mois" },
        { name: "Vitamine B12", dosage: "1000 µg", frequency: "1 injection/semaine", duration: "1 mois" },
        { name: "Acide Folique", dosage: "5 mg", frequency: "1 comprimé par jour", duration: "3 mois" },
      ],
      emergency_level: "moyen"
    },
    high: {
      diagnosis: "Polyglobulie ou leucocytose détectée. Valeurs élevées des éléments sanguins pouvant indiquer une infection, une inflammation ou un trouble hématologique.",
      advice: "Hydratation abondante (2L d'eau/jour minimum). Consulter un hématologue si les valeurs persistent. Éviter les efforts physiques intenses.",
      prescriptions: [{ name: "Aspégic", dosage: "100 mg", frequency: "1 sachet par jour", duration: "15 jours" }],
      emergency_level: "moyen"
    },
    normal: {
      diagnosis: "Bilan sanguin dans les normes. Aucune anomalie détectée sur la numération formule sanguine.",
      advice: "Maintenir une alimentation équilibrée et variée. Activité physique régulière recommandée (30 min/jour). Contrôle de routine dans 1 an.",
      prescriptions: [], emergency_level: "faible"
    }
  },
  "Bilan Lipidique": {
    low: {
      diagnosis: "Hypocholestérolémie ou taux de HDL bas. Risque cardiovasculaire accru lié à un profil lipidique défavorable.",
      advice: "Consommer des acides gras oméga-3 (poisson gras, noix). Éviter les graisses saturées. Activité physique régulière.",
      prescriptions: [{ name: "Oméga-3 (Maxepa)", dosage: "1000 mg", frequency: "2 capsules par jour", duration: "3 mois" }],
      emergency_level: "faible"
    },
    high: {
      diagnosis: "Hypercholestérolémie et/ou hypertriglycéridémie détectée. Risque cardiovasculaire augmenté nécessitant une prise en charge.",
      advice: "Régime pauvre en graisses saturées. Augmenter les fibres. Exercice physique 5 fois/semaine pendant 30 min. Arrêt du tabac si applicable.",
      prescriptions: [
        { name: "Atorvastatine", dosage: "20 mg", frequency: "1 comprimé le soir", duration: "6 mois" },
        { name: "Fénofibrate", dosage: "160 mg", frequency: "1 comprimé par jour", duration: "3 mois" },
      ],
      emergency_level: "moyen"
    },
    normal: {
      diagnosis: "Bilan lipidique normal. Pas de dyslipidémie détectée.",
      advice: "Continuer un mode de vie sain. Limiter les aliments riches en graisses saturées. Contrôle annuel recommandé.",
      prescriptions: [], emergency_level: "faible"
    }
  },
  "Bilan Hépatique": {
    low: {
      diagnosis: "Valeurs hépatiques légèrement basses, généralement sans signification pathologique majeure.",
      advice: "Alimentation équilibrée. Éviter l'alcool et les médicaments hépatotoxiques.",
      prescriptions: [], emergency_level: "faible"
    },
    high: {
      diagnosis: "Cytolyse hépatique détectée avec élévation des transaminases. Possible atteinte hépatique d'origine médicamenteuse, virale ou alcoolique.",
      advice: "Arrêt immédiat de l'alcool. Éviter les médicaments hépatotoxiques. Régime léger sans graisses. Hydratation importante.",
      prescriptions: [
        { name: "Desmodium (Hépatoprotecteur)", dosage: "200 mg", frequency: "3 gélules par jour", duration: "1 mois" },
        { name: "Silymarine (Légalon)", dosage: "140 mg", frequency: "1 comprimé 3 fois/jour", duration: "2 mois" },
      ],
      emergency_level: "critique"
    },
    normal: {
      diagnosis: "Fonction hépatique normale. Aucune anomalie des enzymes hépatiques.",
      advice: "Maintenir une consommation d'alcool modérée. Alimentation riche en légumes. Éviter l'automédication excessive.",
      prescriptions: [], emergency_level: "faible"
    }
  },
  "Bilan Rénal": {
    low: {
      diagnosis: "Fonction rénale potentiellement altérée avec DFG diminué. Possible insuffisance rénale débutante.",
      advice: "Hydratation régulière (1.5 à 2L/jour). Réduire le sel et les protéines animales. Éviter les anti-inflammatoires (AINS).",
      prescriptions: [{ name: "Bicarbonate de Sodium", dosage: "500 mg", frequency: "2 gélules par jour", duration: "1 mois" }],
      emergency_level: "moyen"
    },
    high: {
      diagnosis: "Élévation de la créatinine et de l'urée. Surcharge rénale détectée. Possible déshydratation ou atteinte rénale.",
      advice: "Hydratation intensive. Régime hypoprotéique. Arrêt des médicaments néphrotoxiques. Consultation néphrologique urgente recommandée.",
      prescriptions: [{ name: "Kayexalate", dosage: "15 g", frequency: "1 sachet 3 fois/jour", duration: "5 jours" }],
      emergency_level: "critique"
    },
    normal: {
      diagnosis: "Fonction rénale normale. Créatinine et urée dans les valeurs normales.",
      advice: "Boire au moins 1.5L d'eau par jour. Limiter le sel. Éviter les AINS au long cours.",
      prescriptions: [], emergency_level: "faible"
    }
  },
  "Glycémie et Diabète": {
    low: {
      diagnosis: "Hypoglycémie détectée. Glycémie à jeun inférieure aux normes. Risque de malaise hypoglycémique.",
      advice: "Fractionner les repas (5 à 6 petits repas/jour). Toujours avoir du sucre rapide sur soi. Éviter les jeûnes prolongés.",
      prescriptions: [{ name: "Glucose oral", dosage: "15 g", frequency: "En cas de malaise", duration: "À vie" }],
      emergency_level: "moyen"
    },
    high: {
      diagnosis: "Hyperglycémie et/ou HbA1c élevée. Diabète de type 2 suspecté ou mal équilibré.",
      advice: "Régime hypoglucidique strict. Supprimer les sucres rapides et les sodas. Exercice physique quotidien. Surveillance glycémique régulière.",
      prescriptions: [
        { name: "Metformine", dosage: "850 mg", frequency: "1 comprimé matin et soir", duration: "6 mois" },
        { name: "Gliclazide", dosage: "30 mg", frequency: "1 comprimé le matin", duration: "3 mois" },
      ],
      emergency_level: "moyen"
    },
    normal: {
      diagnosis: "Glycémie à jeun et HbA1c dans les normes. Pas de diabète détecté.",
      advice: "Maintenir un poids santé. Limiter les sucres ajoutés. Activité physique régulière.",
      prescriptions: [], emergency_level: "faible"
    }
  },
  "Bilan Thyroïdien": {
    low: {
      diagnosis: "Hypothyroïdie détectée avec TSH élevée et T4/T3 basses. Ralentissement du métabolisme possible.",
      advice: "Prendre le traitement thyroïdien le matin à jeun, 30 min avant le petit-déjeuner. Éviter le soja et le chou en excès.",
      prescriptions: [{ name: "Lévothyroxine (Levothyrox)", dosage: "50 µg", frequency: "1 comprimé le matin à jeun", duration: "À réévaluer dans 6 semaines" }],
      emergency_level: "moyen"
    },
    high: {
      diagnosis: "Hyperthyroïdie suspectée avec TSH basse et T4/T3 élevées. Hyperactivité thyroïdienne.",
      advice: "Éviter les excitants (café, thé). Repos en cas de palpitations. Consultation endocrinologue recommandée.",
      prescriptions: [
        { name: "Carbimazole (Néo-Mercazole)", dosage: "20 mg", frequency: "1 comprimé par jour", duration: "1 mois" },
        { name: "Propranolol", dosage: "40 mg", frequency: "1 comprimé 2 fois/jour", duration: "15 jours" },
      ],
      emergency_level: "moyen"
    },
    normal: {
      diagnosis: "Bilan thyroïdien normal. Fonction thyroïdienne correcte.",
      advice: "Aucune mesure particulière. Consommation modérée d'iode. Contrôle dans 1 an si symptômes.",
      prescriptions: [], emergency_level: "faible"
    }
  },
  "Bilan Inflammatoire": {
    low: {
      diagnosis: "Marqueurs inflammatoires dans les normes basses. Aucun signe d'inflammation systémique.",
      advice: "Aucune mesure particulière nécessaire.",
      prescriptions: [], emergency_level: "faible"
    },
    high: {
      diagnosis: "Syndrome inflammatoire biologique détecté (CRP et/ou VS élevées). Possible infection ou inflammation chronique.",
      advice: "Repos relatif. Hydratation abondante. Surveiller la température. Consulter si fièvre persistante.",
      prescriptions: [
        { name: "Paracétamol", dosage: "1000 mg", frequency: "1 comprimé 3 fois/jour", duration: "5 jours" },
        { name: "Ibuprofène", dosage: "400 mg", frequency: "1 comprimé 2 fois/jour au repas", duration: "5 jours" },
      ],
      emergency_level: "moyen"
    },
    normal: {
      diagnosis: "Aucun syndrome inflammatoire détecté. CRP et VS normales.",
      advice: "Mode de vie sain. Anti-inflammatoires naturels (curcuma, oméga-3) en prévention.",
      prescriptions: [], emergency_level: "faible"
    }
  },
};

const PATIENTS = [
  "Mohamed Ben Ali", "Fatma Trabelsi", "Ahmed Gharbi", "Salma Bouzid",
  "Youssef Hamdi", "Amira Chaari", "Karim Mansour", "Nour Jelassi",
  "Omar Belhadj", "Sana Mrad", "Amine Sfar", "Ines Bouaziz",
  "Mehdi Kallel", "Rania Dridi", "Bilel Jemaa", "Mariam Haddad",
  "Sami Riahi", "Leila Oueslati", "Hichem Zouari", "Cyrine Mahjoub",
  "Ali Sassi", "Hajer Ben Salem", "Wael Ferchichi", "Asma Souissi",
  "Tarek Maamouri", "Rahma Khelifi", "Zied Chouchane", "Emna Ben Amor",
];

const LABS = [
  "Laboratoire Central Tunis", "Labo BioMed Sousse", "Centre d'Analyses Sfax",
  "Laboratoire Pasteur Ariana", "BioLab Monastir", "Labo El Manar",
  "Centre Médical Ben Arous", "Laboratoire Avicenne Nabeul",
];

const DOCTORS = [
  "Dr. Kamel Bouazizi", "Dr. Sonia Gharbi", "Dr. Mourad Trabelsi",
  "Dr. Leila Ben Ahmed", "Dr. Farid Hamdi", "Dr. Amina Khelifi",
];

// ─── Utilitaires ─────────────────────────────────────────────────────────────

function rand(min, max) {
  return +(min + Math.random() * (max - min)).toFixed(2);
}

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function genValue(param, status) {
  const range = param[status] || param.normal;
  const [lo, hi] = range;
  return Number.isInteger(lo) && Number.isInteger(hi) ? randInt(lo, hi) : rand(lo, hi);
}

// ─── Génération d'image ──────────────────────────────────────────────────────

function createReportImage(id, testData, patient, lab, doctor, date) {
  const W = 800, H = 1000;
  const canvas = createCanvas(W, H);
  const ctx = canvas.getContext('2d');

  // Fond blanc
  ctx.fillStyle = 'white';
  ctx.fillRect(0, 0, W, H);

  // ── En-tête labo ──
  ctx.fillStyle = '#1a5276';
  ctx.fillRect(0, 0, W, 80);
  ctx.fillStyle = 'white';
  ctx.font = 'bold 22px sans-serif';
  ctx.fillText(lab.toUpperCase(), 20, 40);
  ctx.fillStyle = '#d4e6f1';
  ctx.font = '12px sans-serif';
  ctx.fillText("Compte Rendu d'Analyses Médicales", 20, 65);

  let y = 95;

  // ── Infos patient ──
  ctx.strokeStyle = '#2c3e50';
  ctx.lineWidth = 1;
  ctx.strokeRect(15, y, W - 30, 80);
  ctx.fillStyle = '#2c3e50';
  ctx.font = '14px sans-serif';
  ctx.fillText(`Patient : ${patient}`, 25, y + 22);
  ctx.fillText(`Date : ${date}`, 25, y + 45);
  ctx.font = '11px sans-serif';
  ctx.fillText(`Médecin prescripteur : ${doctor}`, 400, y + 22);
  ctx.fillText(`N° Dossier : ${id}`, 400, y + 45);
  ctx.fillText(`Sexe: ${Math.random() > 0.5 ? 'M' : 'F'}  |  Âge: ${randInt(18, 75)} ans`, 25, y + 68);
  y += 95;

  // ── Type d'analyse ──
  ctx.fillStyle = '#2980b9';
  ctx.fillRect(15, y, W - 30, 35);
  ctx.fillStyle = 'white';
  ctx.font = 'bold 16px sans-serif';
  ctx.fillText(testData.type, 25, y + 24);
  y += 50;

  // ── En-têtes tableau ──
  ctx.fillStyle = '#d6eaf8';
  ctx.fillRect(15, y, W - 30, 25);
  ctx.fillStyle = '#2c3e50';
  ctx.font = 'bold 13px sans-serif';
  ctx.fillText("Paramètre", 25, y + 17);
  ctx.fillText("Résultat", 350, y + 17);
  ctx.fillText("Unité", 470, y + 17);
  ctx.fillText("Valeurs Normales", 570, y + 17);
  y += 30;

  // ── Lignes de résultats ──
  testData.params.forEach((p, i) => {
    ctx.fillStyle = i % 2 === 0 ? '#f8f9fa' : 'white';
    ctx.fillRect(15, y, W - 30, 28);

    const isNormal = p.value >= p.normal[0] && p.value <= p.normal[1];
    const flag = isNormal ? '' : (p.value < p.normal[0] ? ' ▼' : ' ▲');

    ctx.font = '13px sans-serif';
    ctx.fillStyle = '#2c3e50';
    ctx.fillText(p.name, 25, y + 19);

    ctx.fillStyle = isNormal ? '#27ae60' : '#e74c3c';
    ctx.font = isNormal ? '13px sans-serif' : 'bold 13px sans-serif';
    ctx.fillText(`${p.value}${flag}`, 350, y + 19);

    ctx.fillStyle = '#7f8c8d';
    ctx.font = '12px sans-serif';
    ctx.fillText(p.unit, 470, y + 19);
    ctx.fillText(`${p.normal[0]} - ${p.normal[1]}`, 570, y + 19);
    y += 30;
  });

  // ── Notes ──
  y += 15;
  ctx.strokeStyle = '#bdc3c7';
  ctx.beginPath();
  ctx.moveTo(15, y);
  ctx.lineTo(W - 15, y);
  ctx.stroke();
  y += 15;
  ctx.fillStyle = '#95a5a6';
  ctx.font = '11px sans-serif';
  ctx.fillText("Note : Les valeurs hors normes sont signalées en rouge avec ▲ (élevé) ou ▼ (bas).", 25, y);
  y += 18;
  ctx.fillText("Ce document est un rapport d'analyses médicales à caractère confidentiel.", 25, y);

  // ── Pied de page ──
  ctx.fillStyle = '#1a5276';
  ctx.fillRect(0, H - 40, W, 40);
  ctx.fillStyle = '#d4e6f1';
  ctx.font = '11px sans-serif';
  ctx.fillText(`© ${lab} - Résultats confidentiels - Ne pas diffuser`, 20, H - 18);

  return canvas.toBuffer('image/jpeg', { quality: 0.95 });
}

// ─── Génération principale ───────────────────────────────────────────────────

function main() {
  if (!fs.existsSync(DATASET_DIR)) fs.mkdirSync(DATASET_DIR, { recursive: true });

  const entries = [];
  console.log(`\n🏥 Génération de ${NUM_SAMPLES} rapports médicaux synthétiques...\n`);

  for (let i = 0; i < NUM_SAMPLES; i++) {
    const id = `MED_${String(i).padStart(4, '0')}`;
    const template = pick(BLOOD_TESTS);
    const patient = pick(PATIENTS);
    const lab = pick(LABS);
    const doctor = pick(DOCTORS);
    const date = `${randInt(1, 28).toString().padStart(2, '0')}/${randInt(1, 12).toString().padStart(2, '0')}/2025`;

    // 40% normal, 30% high, 30% low
    const r = Math.random();
    const status = r < 0.40 ? 'normal' : r < 0.70 ? 'high' : 'low';

    // Générer valeurs
    const testData = {
      type: template.type,
      params: template.params.map(p => {
        const s = status === 'normal' ? 'normal' : (Math.random() < 0.6 ? status : 'normal');
        return { ...p, value: genValue(p, s) };
      })
    };

    // Image
    const imgBuf = createReportImage(id, testData, patient, lab, doctor, date);
    const imgPath = path.join(DATASET_DIR, `${id}.jpg`);
    fs.writeFileSync(imgPath, imgBuf);

    // Réponse IA
    const resp = RESPONSES[testData.type][status];
    const abnormals = testData.params
      .filter(p => p.value < p.normal[0] || p.value > p.normal[1])
      .map(p => `${p.name}: ${p.value} ${p.unit} (${p.value < p.normal[0] ? 'bas' : 'élevé'}, norme: ${p.normal[0]}-${p.normal[1]})`);

    const aiResponse = {
      diagnosis: resp.diagnosis + (abnormals.length ? ` Paramètres anormaux : ${abnormals.join('; ')}.` : ''),
      advice: resp.advice,
      prescription_suggestions: resp.prescriptions,
      emergency_level: resp.emergency_level
    };

    const aiStr = JSON.stringify(aiResponse, null, 2);

    // Fichier texte
    fs.writeFileSync(path.join(DATASET_DIR, `${id}.txt`), aiStr, 'utf-8');

    // Entrée JSONL
    entries.push({
      id,
      image: imgPath,
      conversations: [
        { from: "human", value: "<image>\nAnalyse cette analyse médicale et donne le diagnostic, les conseils et l'ordonnance. Réponds en JSON structuré." },
        { from: "gpt", value: aiStr }
      ]
    });

    const icon = status === 'normal' ? '✅' : (status === 'high' ? '⚠️' : '🔻');
    console.log(`  ${icon} ${id} | ${testData.type.padEnd(40)} | ${status.padEnd(6)} | ${patient}`);
  }

  // Sauvegarder JSONL
  const jsonlContent = entries.map(e => JSON.stringify(e)).join('\n') + '\n';
  fs.writeFileSync(OUTPUT_JSONL, jsonlContent, 'utf-8');

  // Stats
  const stats = {};
  entries.forEach(e => {
    const level = JSON.parse(e.conversations[1].value).emergency_level;
    stats[level] = (stats[level] || 0) + 1;
  });

  console.log(`\n${'='.repeat(60)}`);
  console.log(`✅ Dataset généré avec succès !`);
  console.log(`   📁 Images : ${DATASET_DIR}/ (${NUM_SAMPLES} fichiers .jpg)`);
  console.log(`   📄 Textes : ${DATASET_DIR}/ (${NUM_SAMPLES} fichiers .txt)`);
  console.log(`   📋 JSONL  : ${OUTPUT_JSONL} (${NUM_SAMPLES} entrées)`);
  console.log(`${'='.repeat(60)}`);
  console.log(`\n📊 Répartition des niveaux d'urgence :`);
  Object.entries(stats).sort().forEach(([level, count]) => {
    console.log(`   ${level.padEnd(10)} : ${count} cas (${Math.round(count / NUM_SAMPLES * 100)}%)`);
  });
}

main();
