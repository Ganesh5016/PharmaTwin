"""Simulations API"""
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional
import numpy as np
from app.api.v1.auth import get_current_user
from app.models.models import User

router = APIRouter()

class SimulationRequest(BaseModel):
    batch_id: Optional[str] = None
    drug_name: str
    temperature_c: float = 25.0
    humidity_rh: float = 60.0
    time_months: int = 24
    n_monte_carlo: int = 1000
    simulation_type: str = "stability"

@router.post("/run")
async def run_simulation(
    request: SimulationRequest,
    current_user: User = Depends(get_current_user),
):
    # Monte Carlo simulation
    rng = np.random.default_rng(42)
    
    # Sample from parameter distributions
    temps = rng.normal(request.temperature_c, 2.0, request.n_monte_carlo)
    humids = rng.normal(request.humidity_rh, 5.0, request.n_monte_carlo)
    
    # Degradation rate for each simulation
    Ea = 80_000
    R = 8.314
    T_ref = 298.15
    arr_factors = np.exp(Ea / R * (1/T_ref - 1/(temps + 273.15)))
    humidity_factors = 1 + (humids - 40) * 0.003
    rates = 0.012 * arr_factors * humidity_factors
    shelf_lives = -np.log(0.90) / rates * 12
    
    percentiles = np.percentile(shelf_lives, [5, 25, 50, 75, 95])
    
    return {
        "simulation_type": request.simulation_type,
        "n_simulations": request.n_monte_carlo,
        "mean_shelf_life": float(np.mean(shelf_lives)),
        "std_shelf_life": float(np.std(shelf_lives)),
        "percentile_5": float(percentiles[0]),
        "percentile_25": float(percentiles[1]),
        "percentile_50": float(percentiles[2]),
        "percentile_75": float(percentiles[3]),
        "percentile_95": float(percentiles[4]),
        "histogram": {
            "bins": list(np.linspace(6, 36, 20)),
            "counts": list(np.histogram(shelf_lives, bins=20)[0].astype(float)),
        },
        "risk_probability": float(np.mean(shelf_lives < 12)),
    }

@router.post("/environmental")
async def run_environmental_simulation(
    request: SimulationRequest,
    current_user: User = Depends(get_current_user),
):
    months = list(range(0, request.time_months + 1))
    Ea = 80_000
    R = 8.314
    T_ref = 298.15
    arr = np.exp(Ea / R * (1/T_ref - 1/(request.temperature_c + 273.15)))
    humidity_f = 1 + (request.humidity_rh - 40) * 0.003
    rate = 0.012 * arr * humidity_f

    stability = [float(np.exp(-rate * m)) for m in months]
    
    return {
        "months": months,
        "stability_profile": stability,
        "degradation_rate": float(rate),
        "arrhenius_factor": float(arr),
    }
