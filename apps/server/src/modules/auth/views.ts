import type { Account, DeviceBinding } from '@prisma/client';
import type { AccountView, DeviceBindingView } from './dto/guest.dto';

export function accountView(a: Pick<Account, 'id' | 'status' | 'isGuest' | 'displayName' | 'username' | 'createdAt'>): AccountView {
  return {
    id: a.id,
    status: a.status,
    is_guest: a.isGuest,
    display_name: a.displayName,
    username: a.username,
    created_at: a.createdAt.toISOString(),
  };
}

export function bindingView(b: Pick<DeviceBinding, 'id' | 'role' | 'deviceHash' | 'boundAt'>): DeviceBindingView {
  return { id: b.id, role: b.role, device_hash: b.deviceHash, bound_at: b.boundAt.toISOString() };
}
