import { $fetch, type $Fetch } from "ofetch";

let apiClient: ReturnType<typeof $fetch.create> | null = null;

export const useApi = (): $Fetch => {
  const runtimeConfig = useRuntimeConfig();

  if (!apiClient) {
    apiClient = $fetch.create({
      baseURL: runtimeConfig.public.apiBase,
      credentials: "include",
      onResponseError({ response }) {
        console.error("API error", response.status, response._data);
      },
    });
  }

  return apiClient;
};

