interface ToastPayload {
  id: number;
  title: string;
  message?: string;
  variant?: "success" | "error" | "info";
  timeout?: number;
}

export const useToasts = () => {
  const toasts = useState<ToastPayload[]>("toasts", () => []);
  const counter = useState<number>("toast-counter", () => 0);

  function push(toast: Omit<ToastPayload, "id">) {
    const id = ++counter.value;
    const payload: ToastPayload = {
      id,
      timeout: 5000,
      variant: "info",
      ...toast,
    };
    toasts.value.push(payload);
    if (payload.timeout) {
      setTimeout(() => dismiss(id), payload.timeout);
    }
  }

  function dismiss(id: number) {
    toasts.value = toasts.value.filter((toast) => toast.id !== id);
  }

  return {
    toasts,
    push,
    dismiss,
  };
};

export type { ToastPayload };

