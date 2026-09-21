import { auth } from '../firebase';

export class OrderApiError extends Error {
  constructor(
    message: string,
    public readonly code: string = 'ORDER_API_ERROR',
    public readonly status: number = 400
  ) {
    super(message);
    this.name = 'OrderApiError';
  }
}

export interface OrderCommandResponse<T = unknown> {
  success: boolean;
  order?: T;
  event?: unknown;
  isReplay?: boolean;
  code?: string;
  message?: string;
}

export async function postOrderCommand<T = unknown>(
  body: Record<string, unknown>
): Promise<OrderCommandResponse<T>> {
  const currentUser = auth.currentUser;
  if (!currentUser) {
    throw new OrderApiError('Vui lòng đăng nhập để thực hiện thao tác với đơn hàng.', 'UNAUTHENTICATED', 401);
  }

  const idToken = await currentUser.getIdToken();
  const response = await fetch('/api/orders', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify(body),
  });

  const payload = await response.json().catch(() => ({} as OrderCommandResponse<T>));
  if (!response.ok || payload.success === false) {
    throw new OrderApiError(
      payload.message || 'Không thể cập nhật đơn hàng.',
      payload.code || 'ORDER_API_ERROR',
      response.status
    );
  }

  return payload as OrderCommandResponse<T>;
}
