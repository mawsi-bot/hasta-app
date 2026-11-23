import { SetMetadata } from '@nestjs/common';

export const PUBLIC_META = 'hasta:public';
/** Deny-by-default: every route requires a session unless explicitly marked @Public(). */
export const Public = () => SetMetadata(PUBLIC_META, true);
