from fastapi import APIRouter, HTTPException
import httpx
import logging
from typing import List, Optional
from pydantic import BaseModel

router = APIRouter()
logger = logging.getLogger(__name__)

class AlternativeDrug(BaseModel):
    brand_name: str
    generic_name: str
    pharm_class: List[str]
    route: List[str]

class AlternativesResponse(BaseModel):
    drug_searched: str
    alternatives: List[AlternativeDrug]

@router.get("/", response_model=AlternativesResponse)
async def get_alternatives(drug_name: str, limit: int = 5):
    """
    Fetch drug alternatives based on pharmacologic class using the openFDA API.
    This uses real U.S. FDA data to find substitutes if a drug is unavailable or degrading.
    """
    # 1. First search openFDA for the drug to find its pharmacologic class
    base_url = "https://api.fda.gov/drug/label.json"
    
    async with httpx.AsyncClient() as client:
        try:
            # Search by generic name
            response = await client.get(f'{base_url}?search=openfda.generic_name:"{drug_name}"&limit=1')
            if response.status_code != 200:
                # Fallback to searching by brand name
                response = await client.get(f'{base_url}?search=openfda.brand_name:"{drug_name}"&limit=1')
            
            if response.status_code != 200:
                raise HTTPException(status_code=404, detail="Drug not found in openFDA database.")
                
            data = response.json()
            results = data.get("results", [])
            if not results:
                raise HTTPException(status_code=404, detail="Drug not found in openFDA database.")
                
            drug_info = results[0].get("openfda", {})
            pharm_classes = drug_info.get("pharm_class_epc", [])
            
            if not pharm_classes:
                # If no EPC class, try MOA or PE class
                pharm_classes = drug_info.get("pharm_class_moa", []) + drug_info.get("pharm_class_pe", [])
                
            if not pharm_classes:
                raise HTTPException(status_code=404, detail="Could not determine pharmacologic class for alternatives.")
                
            primary_class = pharm_classes[0]
            
            # 2. Search for other drugs in the same class
            alt_response = await client.get(
                f'{base_url}?search=openfda.pharm_class_epc:"{primary_class}"+AND+NOT+openfda.generic_name:"{drug_name}"&limit={limit}'
            )
            
            alternatives = []
            if alt_response.status_code == 200:
                alt_data = alt_response.json()
                for item in alt_data.get("results", []):
                    openfda = item.get("openfda", {})
                    
                    # Get generic and brand names safely
                    brand_name = openfda.get("brand_name", ["Unknown"])[0]
                    generic = openfda.get("generic_name", ["Unknown"])[0]
                    route = openfda.get("route", ["Unknown"])
                    p_class = openfda.get("pharm_class_epc", [primary_class])
                    
                    # Avoid duplicates
                    if not any(a.generic_name.lower() == generic.lower() for a in alternatives):
                        alternatives.append(AlternativeDrug(
                            brand_name=brand_name,
                            generic_name=generic,
                            pharm_class=p_class,
                            route=route
                        ))
            
            return AlternativesResponse(
                drug_searched=drug_name,
                alternatives=alternatives
            )
            
        except httpx.RequestError as e:
            logger.error(f"Error communicating with openFDA API: {e}")
            raise HTTPException(status_code=503, detail="Failed to connect to FDA database.")
