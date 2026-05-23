"""
PharmaTwin AI Chat Assistant
Smart pharmaceutical assistant powered by OpenFDA + PharmaTwin Predictor.
No external LLM API key required - uses rule-based NLP + real drug data.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import httpx
import re
import logging

from app.api.v1.auth import get_current_user
from app.models.models import User
from ml.inference.predictor import PharmaTwinPredictor

router = APIRouter()
logger = logging.getLogger(__name__)
predictor = PharmaTwinPredictor()


class ChatMessage(BaseModel):
    role: str  # "user" or "assistant"
    content: str


class ChatRequest(BaseModel):
    message: str
    history: Optional[List[ChatMessage]] = []


class ChatResponse(BaseModel):
    reply: str
    data: Optional[dict] = None
    source: Optional[str] = None


# ── Drug knowledge base ──────────────────────────────────────────────────────
DRUG_INFO = {
    "ibuprofen": {
        "class": "NSAID (Non-Steroidal Anti-Inflammatory Drug)",
        "uses": "Pain relief, fever reduction, anti-inflammation",
        "common_doses": "200mg, 400mg, 600mg, 800mg",
        "side_effects": "Stomach upset, heartburn, dizziness, headache",
        "storage": "Store at 20-25°C. Protect from moisture.",
        "bcs_class": "II (Low solubility, High permeability)",
        "half_life": "2-4 hours",
    },
    "metformin": {
        "class": "Biguanide (Antidiabetic)",
        "uses": "Type 2 diabetes management, insulin resistance",
        "common_doses": "500mg, 850mg, 1000mg",
        "side_effects": "Nausea, diarrhea, stomach pain, lactic acidosis (rare)",
        "storage": "Store at 20-25°C. Keep container tightly closed.",
        "bcs_class": "III (High solubility, Low permeability)",
        "half_life": "4-8.7 hours",
    },
    "amlodipine": {
        "class": "Calcium Channel Blocker (Antihypertensive)",
        "uses": "High blood pressure, angina (chest pain)",
        "common_doses": "2.5mg, 5mg, 10mg",
        "side_effects": "Swelling of ankles, dizziness, flushing, fatigue",
        "storage": "Store at 15-30°C. Protect from light.",
        "bcs_class": "I (High solubility, High permeability)",
        "half_life": "30-50 hours",
    },
    "atorvastatin": {
        "class": "Statin (HMG-CoA Reductase Inhibitor)",
        "uses": "High cholesterol, cardiovascular disease prevention",
        "common_doses": "10mg, 20mg, 40mg, 80mg",
        "side_effects": "Muscle pain, liver enzyme changes, digestive problems",
        "storage": "Store at 20-25°C. Protect from moisture and light.",
        "bcs_class": "II (Low solubility, High permeability)",
        "half_life": "14 hours",
    },
    "paracetamol": {
        "class": "Analgesic/Antipyretic",
        "uses": "Pain relief, fever reduction",
        "common_doses": "325mg, 500mg, 650mg, 1000mg",
        "side_effects": "Rare at therapeutic doses. Liver damage at high doses.",
        "storage": "Store at 20-25°C. Protect from moisture.",
        "bcs_class": "I (High solubility, High permeability)",
        "half_life": "1-4 hours",
    },
    "aspirin": {
        "class": "NSAID / Antiplatelet",
        "uses": "Pain relief, fever, anti-inflammation, blood clot prevention",
        "common_doses": "75mg, 81mg, 325mg, 500mg",
        "side_effects": "Stomach irritation, bleeding risk, tinnitus",
        "storage": "Store at 25°C. Protect from moisture.",
        "bcs_class": "I (High solubility, High permeability)",
        "half_life": "15-20 minutes (aspirin), 2-3 hours (salicylate)",
    },
    "omeprazole": {
        "class": "Proton Pump Inhibitor (PPI)",
        "uses": "GERD, stomach ulcers, acid reflux",
        "common_doses": "10mg, 20mg, 40mg",
        "side_effects": "Headache, nausea, diarrhea, vitamin B12 deficiency (long-term)",
        "storage": "Store at 15-25°C. Protect from light and moisture.",
        "bcs_class": "II (Low solubility, High permeability)",
        "half_life": "0.5-1 hour",
    },
    "amoxicillin": {
        "class": "Penicillin-type Antibiotic",
        "uses": "Bacterial infections (ear, throat, urinary, skin)",
        "common_doses": "250mg, 500mg, 875mg",
        "side_effects": "Diarrhea, nausea, rash, allergic reactions",
        "storage": "Store at 20-25°C. Reconstituted: refrigerate, use within 14 days.",
        "bcs_class": "I (High solubility, High permeability)",
        "half_life": "1-1.5 hours",
    },
}


def _extract_drug_name(message: str) -> Optional[str]:
    """Extract a drug name from the user message."""
    msg_lower = message.lower()
    for drug in DRUG_INFO:
        if drug in msg_lower:
            return drug
    # Also check common brand names
    brand_map = {
        "advil": "ibuprofen", "motrin": "ibuprofen", "nurofen": "ibuprofen",
        "glucophage": "metformin", "norvasc": "amlodipine",
        "lipitor": "atorvastatin", "tylenol": "paracetamol", "calpol": "paracetamol",
        "disprin": "aspirin", "prilosec": "omeprazole", "augmentin": "amoxicillin",
    }
    for brand, generic in brand_map.items():
        if brand in msg_lower:
            return generic
    return None


def _detect_intent(message: str) -> str:
    """Detect what the user is asking about."""
    msg = message.lower()

    if any(w in msg for w in ["predict", "stability", "shelf life", "how long", "degrade", "degradation"]):
        return "predict"
    if any(w in msg for w in ["alternative", "substitute", "replacement", "instead of", "similar"]):
        return "alternatives"
    if any(w in msg for w in ["side effect", "adverse", "reaction", "danger"]):
        return "side_effects"
    if any(w in msg for w in ["dose", "dosage", "how much", "strength"]):
        return "dosage"
    if any(w in msg for w in ["store", "storage", "keep", "temperature", "refrigerat"]):
        return "storage"
    if any(w in msg for w in ["what is", "tell me about", "info", "information", "describe", "explain"]):
        return "info"
    if any(w in msg for w in ["use", "used for", "treat", "indication", "purpose"]):
        return "uses"
    if any(w in msg for w in ["hello", "hi ", "hey", "greet"]):
        return "greeting"
    if any(w in msg for w in ["help", "what can you", "how do i", "guide"]):
        return "help"
    if any(w in msg for w in ["ph", "formulation", "excipient", "tablet", "capsule"]):
        return "formulation"

    return "general"


async def _fetch_openfda_info(drug_name: str) -> Optional[dict]:
    """Fetch real drug information from OpenFDA."""
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                f'https://api.fda.gov/drug/label.json?search=openfda.generic_name:"{drug_name}"&limit=1'
            )
            if resp.status_code == 200:
                results = resp.json().get("results", [])
                if results:
                    label = results[0]
                    return {
                        "purpose": (label.get("purpose") or ["N/A"])[0][:300],
                        "warnings": (label.get("warnings") or ["N/A"])[0][:300],
                        "dosage": (label.get("dosage_and_administration") or ["N/A"])[0][:300],
                        "interactions": (label.get("drug_interactions") or ["N/A"])[0][:300],
                    }
    except Exception as e:
        logger.warning(f"OpenFDA fetch failed: {e}")
    return None


async def _fetch_alternatives(drug_name: str) -> List[str]:
    """Fetch real alternatives from OpenFDA."""
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            # First get the drug's class
            resp = await client.get(
                f'https://api.fda.gov/drug/label.json?search=openfda.generic_name:"{drug_name}"&limit=1'
            )
            if resp.status_code == 200:
                results = resp.json().get("results", [])
                if results:
                    openfda = results[0].get("openfda", {})
                    pharm_class = openfda.get("pharm_class_epc", [])
                    if pharm_class:
                        # Search for alternatives in the same class
                        alt_resp = await client.get(
                            f'https://api.fda.gov/drug/label.json?search=openfda.pharm_class_epc:"{pharm_class[0]}"+AND+NOT+openfda.generic_name:"{drug_name}"&limit=5'
                        )
                        if alt_resp.status_code == 200:
                            alt_results = alt_resp.json().get("results", [])
                            names = []
                            for item in alt_results:
                                gn = item.get("openfda", {}).get("generic_name", [""])[0]
                                bn = item.get("openfda", {}).get("brand_name", [""])[0]
                                if gn and gn.lower() not in [n.lower() for n in names]:
                                    names.append(f"{bn} ({gn})" if bn else gn)
                            return names
    except Exception as e:
        logger.warning(f"OpenFDA alternatives fetch failed: {e}")
    return []


@router.post("/ask", response_model=ChatResponse)
async def chat_ask(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    """AI pharmaceutical assistant endpoint."""
    message = request.message.strip()
    if not message:
        raise HTTPException(status_code=400, detail="Message cannot be empty.")

    intent = _detect_intent(message)
    drug = _extract_drug_name(message)

    # ── Greeting ──
    if intent == "greeting":
        return ChatResponse(
            reply="Hello! 👋 I'm the PharmaTwin AI Assistant. I can help you with:\n\n"
                  "🔬 **Drug Information** — Ask about any drug (e.g. 'Tell me about Ibuprofen')\n"
                  "📊 **Stability Predictions** — Predict shelf life (e.g. 'Predict stability of Metformin at 40°C')\n"
                  "💊 **Alternatives** — Find substitutes (e.g. 'What are alternatives to Aspirin?')\n"
                  "📋 **Dosage & Side Effects** — Get details on any medication\n"
                  "🏭 **Formulation Advice** — pH, temperature, packaging guidance\n\n"
                  "What would you like to know?",
            source="PharmaTwin AI"
        )

    # ── Help ──
    if intent == "help":
        return ChatResponse(
            reply="Here's how to use the PharmaTwin AI Assistant:\n\n"
                  "• Type a **drug name** to get detailed information\n"
                  "• Ask about **stability** or **shelf life** for AI predictions\n"
                  "• Ask for **alternatives** or **substitutes** for any drug\n"
                  "• Ask about **side effects**, **dosage**, or **storage** conditions\n"
                  "• Ask about **formulation** parameters like pH, temperature\n\n"
                  "**Example questions:**\n"
                  "- 'What is Metformin used for?'\n"
                  "- 'Predict shelf life of Ibuprofen at 40°C and 75% humidity'\n"
                  "- 'What are alternatives to Atorvastatin?'\n"
                  "- 'How should I store Amoxicillin?'",
            source="PharmaTwin AI"
        )

    # ── Drug-specific queries ──
    if drug:
        info = DRUG_INFO.get(drug, {})

        if intent == "predict":
            # Extract temperature if mentioned
            temp_match = re.search(r'(\d+)\s*°?\s*[Cc]', message)
            temp = float(temp_match.group(1)) if temp_match else 25.0

            humid_match = re.search(r'(\d+)\s*%?\s*(?:rh|humidity)', message.lower())
            humidity = float(humid_match.group(1)) if humid_match else 60.0

            ph_match = re.search(r'ph\s*(\d+\.?\d*)', message.lower())
            ph = float(ph_match.group(1)) if ph_match else 7.0

            try:
                result = predictor.predict(
                    drug_name=drug,
                    dosage_form="Tablet",
                    drug_load_percent=40.0,
                    strength_mg=400.0,
                    temperature_c=temp,
                    humidity_rh=humidity,
                    ph_level=ph,
                    packaging_type="Blister",
                    excipients={},
                    ich_zone="II",
                )
                return ChatResponse(
                    reply=f"🔬 **Stability Prediction for {drug.title()}**\n\n"
                          f"**Conditions:** {temp}°C / {humidity}% RH / pH {ph}\n\n"
                          f"📅 **Predicted Shelf Life:** {result['shelf_life_months']:.1f} months\n"
                          f"   ({result['shelf_life_lower']:.1f} – {result['shelf_life_upper']:.1f} months, 95% CI)\n\n"
                          f"⚠️ **Degradation Risk:** {result['degradation_risk']*100:.0f}%\n"
                          f"✅ **Stability Score:** {result['stability_score']*100:.0f}%\n"
                          f"🎯 **Model Confidence:** {result['confidence']*100:.0f}%\n\n"
                          f"💡 {result['explanation']}",
                    data=result,
                    source="PharmaTwin AI Ensemble (LSTM + XGBoost + Bayesian NN + GRU)"
                )
            except Exception as e:
                return ChatResponse(reply=f"❌ Prediction failed: {str(e)}", source="Error")

        if intent == "alternatives":
            alts = await _fetch_alternatives(drug)
            if alts:
                alt_list = "\n".join([f"  • {a}" for a in alts])
                return ChatResponse(
                    reply=f"💊 **Alternatives to {drug.title()}** (same therapeutic class):\n\n{alt_list}\n\n"
                          f"⚕️ *Always consult your doctor before switching medications.*",
                    source="OpenFDA (U.S. FDA)"
                )
            else:
                return ChatResponse(
                    reply=f"I couldn't find alternatives for {drug.title()} in the FDA database right now. "
                          f"Please consult a pharmacist for therapeutic substitutes.",
                    source="OpenFDA"
                )

        if intent == "side_effects":
            se = info.get("side_effects", "Information not available.")
            fda_data = await _fetch_openfda_info(drug)
            extra = ""
            if fda_data and fda_data.get("warnings"):
                extra = f"\n\n📋 **FDA Label Warnings:**\n{fda_data['warnings']}"
            return ChatResponse(
                reply=f"⚠️ **Side Effects of {drug.title()}:**\n\n{se}{extra}\n\n"
                      f"*If you experience severe side effects, seek medical attention immediately.*",
                source="PharmaTwin DB + OpenFDA"
            )

        if intent == "dosage":
            doses = info.get("common_doses", "Not available")
            fda_data = await _fetch_openfda_info(drug)
            extra = ""
            if fda_data and fda_data.get("dosage"):
                extra = f"\n\n📋 **FDA Dosage Info:**\n{fda_data['dosage']}"
            return ChatResponse(
                reply=f"💊 **Dosage for {drug.title()}:**\n\n"
                      f"**Common Strengths:** {doses}\n"
                      f"**Half-life:** {info.get('half_life', 'N/A')}{extra}\n\n"
                      f"*Always follow your doctor's prescribed dosage.*",
                source="PharmaTwin DB + OpenFDA"
            )

        if intent == "storage":
            return ChatResponse(
                reply=f"🏭 **Storage for {drug.title()}:**\n\n"
                      f"{info.get('storage', 'Store at controlled room temperature.')}\n\n"
                      f"**BCS Classification:** {info.get('bcs_class', 'N/A')}\n"
                      f"**Drug Class:** {info.get('class', 'N/A')}",
                source="PharmaTwin DB"
            )

        if intent == "uses":
            return ChatResponse(
                reply=f"💡 **Uses of {drug.title()}:**\n\n"
                      f"**Therapeutic Class:** {info.get('class', 'N/A')}\n"
                      f"**Indications:** {info.get('uses', 'N/A')}\n"
                      f"**Common Doses:** {info.get('common_doses', 'N/A')}",
                source="PharmaTwin DB"
            )

        if intent == "formulation":
            props = predictor.DRUG_DB.get(drug, {})
            return ChatResponse(
                reply=f"🧪 **Formulation Data for {drug.title()}:**\n\n"
                      f"**Molecular Weight:** {props.get('mw', 'N/A')} g/mol\n"
                      f"**LogP:** {props.get('logp', 'N/A')}\n"
                      f"**pKa:** {props.get('pka', 'N/A')}\n"
                      f"**BCS Class:** {info.get('bcs_class', 'N/A')}\n"
                      f"**Base Stability:** {props.get('base_stability', 'N/A')}\n\n"
                      f"💡 *For optimal stability, maintain pH close to pKa ({props.get('pka', 'N/A')}) "
                      f"and store at controlled temperature (20-25°C).*",
                source="PharmaTwin DB"
            )

        # General info about the drug
        fda_data = await _fetch_openfda_info(drug)
        reply = (
            f"ℹ️ **{drug.title()} — Drug Profile**\n\n"
            f"**Class:** {info.get('class', 'N/A')}\n"
            f"**Uses:** {info.get('uses', 'N/A')}\n"
            f"**Common Doses:** {info.get('common_doses', 'N/A')}\n"
            f"**Side Effects:** {info.get('side_effects', 'N/A')}\n"
            f"**Half-life:** {info.get('half_life', 'N/A')}\n"
            f"**BCS Class:** {info.get('bcs_class', 'N/A')}\n"
            f"**Storage:** {info.get('storage', 'N/A')}"
        )
        if fda_data:
            reply += f"\n\n📋 **FDA Drug Interactions:**\n{fda_data.get('interactions', 'N/A')}"

        return ChatResponse(reply=reply, source="PharmaTwin DB + OpenFDA")

    # ── General pharmaceutical queries without a specific drug ──
    if intent == "formulation":
        return ChatResponse(
            reply="🧪 **Formulation Guidance:**\n\n"
                  "For tablet formulation, key parameters to consider:\n\n"
                  "• **pH:** Maintain near the drug's pKa for optimal stability\n"
                  "• **Temperature:** ICH Zone II standard is 25°C/60% RH\n"
                  "• **Excipients:** Choose based on BCS classification\n"
                  "• **Packaging:** Alu-Alu blister offers best moisture protection (factor: 0.99)\n\n"
                  "Tell me a specific drug name and I can give tailored advice!",
            source="PharmaTwin AI"
        )

    # ── Fallback ──
    return ChatResponse(
        reply=f"I understand you're asking about: *\"{message}\"*\n\n"
              f"I can best help you if you mention a specific drug name. Try asking:\n"
              f"• 'Tell me about **Ibuprofen**'\n"
              f"• 'Predict stability of **Metformin** at 40°C'\n"
              f"• 'What are alternatives to **Aspirin**?'\n"
              f"• 'Side effects of **Omeprazole**'\n\n"
              f"I have detailed data on: Ibuprofen, Metformin, Amlodipine, Atorvastatin, "
              f"Paracetamol, Aspirin, Omeprazole, and Amoxicillin.",
        source="PharmaTwin AI"
    )
