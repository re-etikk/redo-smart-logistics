// cargoCompatibility.js — REDO Multi-Cargo Safety & Co-loading Matrix
// Ensures hazardous, perishable, fragile, and food items are safely isolated according to transport laws.

export const PROHIBITED_PAIRS = new Set([
  'food|chemicals',
  'chemicals|food',
  'packaged_food|chemicals',
  'chemicals|packaged_food',
  'food|fertilizers',
  'fertilizers|food',
  'food|hazardous',
  'hazardous|food',
  'fragile|heavy_machinery',
  'heavy_machinery|fragile',
  'glass|heavy_machinery',
  'heavy_machinery|glass',
  'chemicals|fragile',
  'fragile|chemicals',
]);

export const CONDITIONAL_PAIRS = new Set([
  'fragile|general',
  'general|fragile',
  'food|perishable',
  'perishable|food',
  'high_value|general',
  'general|high_value',
  'fmcg|machinery',
  'machinery|fmcg',
]);

/**
 * Normalizes cargo type string into canonical category key.
 */
export function normalizeCargoCategory(typeStr) {
  if (!typeStr) return 'general';
  const s = typeStr.toLowerCase().trim().replace(/[^a-z0-9]/g, '_');
  if (s.includes('chem') || s.includes('acid') || s.includes('paint') || s.includes('solvent')) return 'chemicals';
  if (s.includes('food') || s.includes('grain') || s.includes('wheat') || s.includes('rice') || s.includes('sugar')) return 'food';
  if (s.includes('fmcg') || s.includes('biscuit') || s.includes('packaged') || s.includes('soap') || s.includes('cosmetic')) return 'fmcg';
  if (s.includes('fertil') || s.includes('pestic')) return 'fertilizers';
  if (s.includes('fragile') || s.includes('glass') || s.includes('ceramic') || s.includes('crockery') || s.includes('electronic')) return 'fragile';
  if (s.includes('heavy') || s.includes('steel') || s.includes('iron') || s.includes('coil') || s.includes('pipe')) return 'heavy_machinery';
  if (s.includes('perish') || s.includes('fruit') || s.includes('vegetable') || s.includes('dairy') || s.includes('pharma')) return 'perishable';
  if (s.includes('valuable') || s.includes('jewel') || s.includes('copper') || s.includes('high_val')) return 'high_value';
  return 'general';
}

/**
 * Checks safety between two individual cargo items.
 */
export function checkTwoCargoCompatibility(typeA, typeB) {
  const normA = normalizeCargoCategory(typeA);
  const normB = normalizeCargoCategory(typeB);

  const pairKey = `${normA}|${normB}`;
  if (PROHIBITED_PAIRS.has(pairKey)) {
    return {
      allowed: false,
      riskLevel: 'prohibited',
      reason: `Strictly Prohibited: Cannot co-load ${normA.toUpperCase()} with ${normB.toUpperCase()} due to severe contamination or safety hazard.`,
    };
  }

  if (CONDITIONAL_PAIRS.has(pairKey)) {
    return {
      allowed: true,
      riskLevel: 'warning',
      reason: `Conditional Co-load: ${normA.toUpperCase()} and ${normB.toUpperCase()} require proper lashing, partition or top-loading separation.`,
    };
  }

  return {
    allowed: true,
    riskLevel: 'safe',
    reason: `Fully Compatible: Safe co-loading under standard transport protocols.`,
  };
}

/**
 * Checks if a candidate cargo can be safely placed in a truck that already contains
 * a list of existing cargo types.
 */
export function checkTruckCoLoadSafety(existingCargoList = [], candidateCargoType) {
  if (!existingCargoList || existingCargoList.length === 0) {
    return {
      allowed: true,
      riskLevel: 'safe',
      reasons: ['Truck currently empty — any legal cargo category permitted.'],
      warnings: [],
    };
  }

  const normCandidate = normalizeCargoCategory(candidateCargoType);
  const warnings = [];
  const prohibitedReasons = [];

  for (const existing of existingCargoList) {
    const check = checkTwoCargoCompatibility(existing, normCandidate);
    if (!check.allowed) {
      prohibitedReasons.push(check.reason);
    } else if (check.riskLevel === 'warning') {
      warnings.push(check.reason);
    }
  }

  if (prohibitedReasons.length > 0) {
    return {
      allowed: false,
      riskLevel: 'prohibited',
      reasons: prohibitedReasons,
      warnings,
    };
  }

  if (warnings.length > 0) {
    return {
      allowed: true,
      riskLevel: 'warning',
      reasons: ['Co-loading permitted with physical partition.'],
      warnings,
    };
  }

  return {
    allowed: true,
    riskLevel: 'safe',
    reasons: ['Fully compatible with existing vehicle cargo inventory.'],
    warnings: [],
  };
}
