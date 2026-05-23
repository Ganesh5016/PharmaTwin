-- PharmaTwin AI Database Initialization
-- PostgreSQL 16

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- for fuzzy search

-- Create initial admin user (password handled by Firebase)
-- This is just reference data

-- Seed drug reference data
CREATE TABLE IF NOT EXISTS drug_reference (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    drug_name VARCHAR(255) NOT NULL UNIQUE,
    iupac_name VARCHAR(500),
    molecular_weight FLOAT,
    log_p FLOAT,
    pka FLOAT,
    bcs_class INTEGER CHECK (bcs_class BETWEEN 1 AND 4),
    molecular_formula VARCHAR(100),
    cas_number VARCHAR(50),
    pharmacological_class VARCHAR(255),
    degradation_pathways JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO drug_reference (drug_name, molecular_weight, log_p, pka, bcs_class, molecular_formula, cas_number)
VALUES
    ('Ibuprofen', 206.28, 3.97, 4.91, 2, 'C13H18O2', '15687-27-1'),
    ('Metformin', 129.16, -1.43, 2.80, 3, 'C4H11N5', '657-24-9'),
    ('Amlodipine', 408.88, 3.00, 8.70, 1, 'C20H25ClN2O5', '88150-42-9'),
    ('Atorvastatin', 558.64, 6.36, 4.46, 2, 'C33H35FN2O5', '134523-00-5'),
    ('Paracetamol', 151.16, 0.49, 9.38, 1, 'C8H9NO2', '103-90-2'),
    ('Aspirin', 180.16, 1.19, 3.49, 1, 'C9H8O4', '50-78-2'),
    ('Omeprazole', 345.42, 2.23, 4.77, 2, 'C17H19N3O3S', '73590-58-6'),
    ('Amoxicillin', 365.40, 0.87, 2.40, 1, 'C16H19N3O5S', '26787-78-0'),
    ('Lisinopril', 405.49, -0.20, 2.50, 3, 'C21H31N3O5', '76547-98-3'),
    ('Simvastatin', 418.57, 4.68, 13.50, 2, 'C25H38O5', '79902-63-9')
ON CONFLICT (drug_name) DO NOTHING;

-- Excipient compatibility matrix
CREATE TABLE IF NOT EXISTS excipient_compatibility (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    excipient_a VARCHAR(255) NOT NULL,
    excipient_b VARCHAR(255) NOT NULL,
    compatibility_score FLOAT CHECK (compatibility_score BETWEEN 0 AND 1),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ICH stability zones reference
CREATE TABLE IF NOT EXISTS ich_stability_zones (
    zone VARCHAR(10) PRIMARY KEY,
    description VARCHAR(255),
    temperature_c FLOAT,
    humidity_rh FLOAT,
    regions TEXT[]
);

INSERT INTO ich_stability_zones VALUES
    ('I',   'Temperate',                    21.0, 45.0, ARRAY['Europe', 'Canada', 'Japan']),
    ('II',  'Subtropical/Mediterranean',    25.0, 60.0, ARRAY['USA', 'EU', 'Japan']),
    ('III', 'Hot/Dry',                      30.0, 35.0, ARRAY['Middle East', 'N. Africa']),
    ('IVa', 'Hot/Humid',                    30.0, 65.0, ARRAY['S. Asia', 'SE. Asia']),
    ('IVb', 'Hot/Very Humid',               30.0, 75.0, ARRAY['Brazil', 'tropical']),
    ('VI',  'Stress (accelerated testing)', 40.0, 75.0, ARRAY['lab'])
ON CONFLICT (zone) DO NOTHING;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_batches_owner ON batches(owner_id);
CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);
CREATE INDEX IF NOT EXISTS idx_batches_drug ON batches USING GIN (to_tsvector('english', drug_name));
CREATE INDEX IF NOT EXISTS idx_predictions_user ON predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_predictions_batch ON predictions(batch_id);
CREATE INDEX IF NOT EXISTS idx_simulations_batch ON simulation_logs(batch_id);

COMMENT ON TABLE drug_reference IS 'Reference database of pharmaceutical compounds with physicochemical properties';
COMMENT ON TABLE ich_stability_zones IS 'ICH Q1A(R2) climatic zones for stability testing';
