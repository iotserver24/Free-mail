import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { mailApi, type SendMessagePayload } from "../lib/api";

export function useMessages() {
  return useQuery({
    queryKey: ["messages"],
    queryFn: mailApi.listMessages,
    refetchInterval: 15_000,
  });
}

export function useMessage(messageId?: string) {
  return useQuery({
    queryKey: ["messages", messageId],
    queryFn: () => mailApi.getMessage(messageId!),
    enabled: Boolean(messageId),
  });
}

export function useSendMessage() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (payload: SendMessagePayload) => mailApi.sendMessage(payload),
    onSuccess: () => {
      client.invalidateQueries({ queryKey: ["messages"] });
    },
  });
}

