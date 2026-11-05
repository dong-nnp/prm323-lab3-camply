import { z } from 'zod';

export const emailAddress = z.string().trim().toLowerCase().pipe(z.email().max(254));
export const fptStudentId = z.string().trim().toUpperCase().regex(/^[A-Z]{2}[0-9]{6}$/);
