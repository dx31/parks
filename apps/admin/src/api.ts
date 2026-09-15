import type { ClientIdentity, Operator, Space, SpaceStatus, Zone } from "./types";

const API_URL = import.meta.env.VITE_API_URL ?? "";

type ApiError = {
  message?: string;
};

async function request<T>(
  path: string,
  init: RequestInit & { token?: string } = {},
): Promise<T> {
  const { token, headers, ...rest } = init;
  const response = await fetch(`${API_URL}${path}`, {
    ...rest,
    headers: {
      Accept: "application/json",
      ...(rest.body ? { "Content-Type": "application/json" } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
  });

  if (!response.ok) {
    let message = `Error ${response.status}`;
    try {
      const json = (await response.json()) as ApiError;
      if (json.message) {
        message = json.message;
      }
    } catch {
      // Keep the status fallback.
    }
    throw new Error(message);
  }

  if (response.status === 204 || response.headers.get("content-length") === "0") {
    return undefined as T;
  }

  return (await response.json()) as T;
}

export function login(username: string, pin: string) {
  return request<{ token: string; operator: Operator }>("/api/auth/login", {
    method: "POST",
    body: JSON.stringify({ username, pin }),
  });
}

export function listZones(token?: string) {
  return request<Zone[]>("/api/zones", { token });
}

export function createZone(token: string, body: { name: string; city: string; videoUrl?: string }) {
  return request<Zone>("/api/zones", {
    token,
    method: "POST",
    body: JSON.stringify(body),
  });
}

export function updateZone(
  token: string,
  id: string,
  body: { name: string; city: string; videoUrl?: string | null },
) {
  return request<Zone>(`/api/zones/${id}`, {
    token,
    method: "PUT",
    body: JSON.stringify(body),
  });
}

export function listSpaces(token?: string, query?: { zoneId?: string; status?: SpaceStatus }) {
  const params = new URLSearchParams();
  if (query?.zoneId) {
    params.set("zoneId", query.zoneId);
  }
  if (query?.status) {
    params.set("status", query.status);
  }
  const suffix = params.size ? `?${params}` : "";
  return request<Space[]>(`/api/spaces${suffix}`, { token });
}

export function createSpace(
  token: string,
  body: {
    code: string;
    zoneId: string;
    latitude: number;
    longitude: number;
    hourlyRate: number;
    notes?: string;
  },
) {
  return request<Space>("/api/spaces", {
    token,
    method: "POST",
    body: JSON.stringify(body),
  });
}

export function updateSpace(
  token: string,
  id: string,
  body: {
    code: string;
    latitude: number;
    longitude: number;
    hourlyRate: number;
    notes?: string | null;
  },
) {
  return request<Space>(`/api/spaces/${id}`, {
    token,
    method: "PUT",
    body: JSON.stringify(body),
  });
}

export function changeSpaceStatus(token: string, id: string, status: SpaceStatus) {
  return request<Space>(`/api/spaces/${id}/status`, {
    token,
    method: "PATCH",
    body: JSON.stringify({ status }),
  });
}

export function reserveSpace(token: string, id: string, dni: string) {
  return request<Space>(`/api/spaces/${id}/reserve`, {
    token,
    method: "POST",
    body: JSON.stringify({ dni }),
  });
}

export function lookupClient(token: string, dni: string) {
  return request<ClientIdentity>(`/api/clients/${dni}`, { token });
}

export function deleteSpace(token: string, id: string) {
  return request<void>(`/api/spaces/${id}`, { token, method: "DELETE" });
}

export function listOperators(token?: string) {
  return request<Operator[]>("/api/operators", { token });
}

export function createOperator(
  token: string,
  body: { name: string; username: string; pin: string },
) {
  return request<Operator>("/api/operators", {
    token,
    method: "POST",
    body: JSON.stringify(body),
  });
}

export function updateOperator(
  token: string,
  id: string,
  body: { name: string; username: string; pin?: string },
) {
  return request<Operator>(`/api/operators/${id}`, {
    token,
    method: "PUT",
    body: JSON.stringify(body),
  });
}

export function deleteOperator(token: string, id: string) {
  return request<void>(`/api/operators/${id}`, { token, method: "DELETE" });
}
