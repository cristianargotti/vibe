<!-- last-reviewed: 2026-03-11 -->

# React & Next.js Standards

Tier 2 reference for frontend applications built with React 18+ and Next.js App Router.

## Custom Hook Patterns

Hooks encapsulate stateful logic. Each hook lives in its own file under `hooks/`.

```tsx
// hooks/use-debounce.ts
import { useEffect, useState } from "react";

export function useDebounce<T>(value: T, delayMs: number = 300): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(timer);
  }, [value, delayMs]);

  return debounced;
}

// hooks/use-pagination.ts
import { useCallback, useMemo, useState } from "react";

interface PaginationState {
  page: number;
  limit: number;
  total: number;
}

export function usePagination(initialLimit: number = 20) {
  const [state, setState] = useState<PaginationState>({
    page: 1,
    limit: initialLimit,
    total: 0,
  });

  const setPage = useCallback(
    (page: number) => setState((s) => ({ ...s, page })),
    [],
  );
  const setTotal = useCallback(
    (total: number) => setState((s) => ({ ...s, total })),
    [],
  );
  const totalPages = useMemo(
    () => Math.ceil(state.total / state.limit),
    [state.total, state.limit],
  );

  return { ...state, totalPages, setPage, setTotal } as const;
}
```

## TanStack Query: Key Factories and Mutations

Centralize query keys in a factory object. Never inline key arrays.

```tsx
// lib/queries/product-queries.ts
export const productKeys = {
  all: ["products"] as const,
  lists: () => [...productKeys.all, "list"] as const,
  list: (filters: ProductFilters) => [...productKeys.lists(), filters] as const,
  details: () => [...productKeys.all, "detail"] as const,
  detail: (id: string) => [...productKeys.details(), id] as const,
};

export function useProducts(filters: ProductFilters) {
  return useQuery({
    queryKey: productKeys.list(filters),
    queryFn: () => api.products.list(filters),
    staleTime: 5 * 60 * 1000,
  });
}

export function useProduct(id: string) {
  return useQuery({
    queryKey: productKeys.detail(id),
    queryFn: () => api.products.get(id),
    enabled: !!id,
  });
}

export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateProductInput) => api.products.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: productKeys.lists() });
    },
  });
}
```

## Zustand Store with Slices

Split large stores into slices. Each slice owns a vertical feature.

```ts
// stores/app-store.ts
import { create } from "zustand";
import { devtools } from "zustand/middleware";

interface CartSlice {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  removeItem: (productId: string) => void;
  clearCart: () => void;
}

interface UISlice {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
}

type AppStore = CartSlice & UISlice;

const createCartSlice = (set: SetState<AppStore>): CartSlice => ({
  items: [],
  addItem: (item) => set((s) => ({ items: [...s.items, item] })),
  removeItem: (productId) =>
    set((s) => ({ items: s.items.filter((i) => i.productId !== productId) })),
  clearCart: () => set({ items: [] }),
});

const createUISlice = (set: SetState<AppStore>): UISlice => ({
  sidebarOpen: false,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
});

export const useAppStore = create<AppStore>()(
  devtools((...args) => ({
    ...createCartSlice(...args),
    ...createUISlice(...args),
  })),
);
```

## Error Boundaries with Recovery

Wrap route segments in error boundaries that offer a retry action.

```tsx
"use client";

import { Component, type ErrorInfo, type ReactNode } from "react";

interface Props {
  children: ReactNode;
  fallback?: (props: { error: Error; reset: () => void }) => ReactNode;
}

interface State {
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error("ErrorBoundary caught:", error, info.componentStack);
  }

  reset = () => this.setState({ error: null });

  render() {
    if (this.state.error) {
      if (this.props.fallback) {
        return this.props.fallback({
          error: this.state.error,
          reset: this.reset,
        });
      }
      return (
        <div role="alert" className="p-6 text-center">
          <h2 className="text-lg font-semibold">Something went wrong</h2>
          <p className="mt-2 text-sm text-gray-600">
            {this.state.error.message}
          </p>
          <button
            onClick={this.reset}
            className="mt-4 rounded bg-blue-600 px-4 py-2 text-white"
          >
            Try again
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}
```

## Skeleton Loader Component

Use a shared skeleton primitive. Compose it for specific layouts.

```tsx
// components/ui/skeleton.tsx
export function Skeleton({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={`animate-pulse rounded bg-gray-200 ${className ?? ""}`}
      {...props}
    />
  );
}

// components/product/product-card-skeleton.tsx
export function ProductCardSkeleton() {
  return (
    <div className="space-y-3 rounded border p-4">
      <Skeleton className="h-48 w-full" />
      <Skeleton className="h-4 w-3/4" />
      <Skeleton className="h-4 w-1/2" />
      <Skeleton className="h-8 w-24" />
    </div>
  );
}
```

## Server Components vs Client Components

Use this decision tree to choose component type.

| Condition                                       | Component Type                    |
| ----------------------------------------------- | --------------------------------- |
| Fetches data at render time                     | Server Component                  |
| Uses `useState`, `useEffect`, or browser APIs   | Client Component (`"use client"`) |
| Handles user interaction (click, submit, hover) | Client Component                  |
| Renders static or data-driven markup only       | Server Component                  |
| Needs access to cookies/headers at request time | Server Component                  |

```tsx
// app/products/page.tsx — Server Component (default)
export default async function ProductsPage() {
  const products = await getProducts(); // direct DB or API call, no hook needed
  return (
    <main>
      <h1>Products</h1>
      <ProductGrid products={products} />
    </main>
  );
}

// components/product/add-to-cart-button.tsx — Client Component
("use client");
export function AddToCartButton({ productId }: { productId: string }) {
  const addItem = useAppStore((s) => s.addItem);
  return (
    <button onClick={() => addItem({ productId, quantity: 1 })}>
      Add to cart
    </button>
  );
}
```

## next/image Optimization

Always use `next/image` with explicit `width`/`height` or `fill` to prevent layout shift.

```tsx
import Image from "next/image";

// Known dimensions
<Image src={product.imageUrl} alt={product.name} width={400} height={300} className="rounded" />

// Fill mode for responsive containers
<div className="relative aspect-video">
  <Image src={product.imageUrl} alt={product.name} fill sizes="(max-width: 768px) 100vw, 50vw" className="object-cover" />
</div>
```

## react-hook-form + Zod Integration

Combine `react-hook-form` with Zod via the resolver. Never validate manually.

```tsx
"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const CheckoutSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2),
  address: z.string().min(5),
  city: z.string().min(2),
  zip: z.string().regex(/^[\dA-Z]{4,10}[-\s]?[\dA-Z]{0,5}$/), // Supports BR, CO, CL, AR formats
});

type CheckoutForm = z.infer<typeof CheckoutSchema>;

export function CheckoutForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CheckoutForm>({
    resolver: zodResolver(CheckoutSchema),
  });

  const onSubmit = async (data: CheckoutForm) => {
    await api.checkout.create(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <input {...register("email")} placeholder="Email" />
        {errors.email && (
          <p className="text-red-500 text-sm">{errors.email.message}</p>
        )}
      </div>
      <div>
        <input {...register("name")} placeholder="Full name" />
        {errors.name && (
          <p className="text-red-500 text-sm">{errors.name.message}</p>
        )}
      </div>
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Placing order..." : "Place order"}
      </button>
    </form>
  );
}
```

## App Router Patterns

Use `loading.tsx` and `error.tsx` conventions per route segment.

```
app/
  layout.tsx          # Root layout with providers
  loading.tsx         # Global loading skeleton
  error.tsx           # Global error boundary
  products/
    page.tsx          # Server Component — fetches product list
    loading.tsx       # Product list skeleton
    [id]/
      page.tsx        # Server Component — fetches single product
      loading.tsx
      error.tsx
```

```tsx
// app/layout.tsx
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <QueryProvider>
          <Navbar />
          {children}
        </QueryProvider>
      </body>
    </html>
  );
}

// app/products/loading.tsx
export default function ProductsLoading() {
  return (
    <div className="grid grid-cols-3 gap-4">
      {Array.from({ length: 6 }).map((_, i) => (
        <ProductCardSkeleton key={i} />
      ))}
    </div>
  );
}
```
