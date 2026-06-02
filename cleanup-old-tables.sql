-- This script drops the old, unused tables from the V1 architecture

-- Drop the old initiatives table that used hardcoded columns (pe, re, cm, pg, gs)
DROP TABLE IF EXISTS initiatives;

-- Drop the settings table that was used during the intermediate 'global weights' experiment
-- (Weights are now stored directly in the categories_rel table)
DROP TABLE IF EXISTS settings;
