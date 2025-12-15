import crypto from 'crypto';

export function normalizeLocation(location: string): string {
  return location
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

export function generateIdempotencyHash(
  userId: string,
  localizacaoCorpo: string,
  dataAproximada: Date | null
): string {
  const normalizedLocation = normalizeLocation(localizacaoCorpo);
  const dateStr = dataAproximada
    ? dataAproximada.toISOString().split('T')[0]
    : 'no-date';
  
  const hashInput = `${userId}|${normalizedLocation}|${dateStr}`;
  
  return crypto.createHash('sha256').update(hashInput).digest('hex');
}
