import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { mailApi, type SendMessagePayload } from "../lib/api";

export function useMessages(inboxId?: string | null) {
  return useQuery({
    queryKey: ["messages", inboxId],
    queryFn: () => mailApi.listMessages(inboxId),
    refetchInterval: 15_000,
  });
}

export function useDomains() {
  return useQuery({
    queryKey: ["domains"],
    queryFn: mailApi.listDomains,
  });
}

export function useEmails() {
  return useQuery({
    queryKey: ["emails"],
    queryFn: mailApi.listEmails,
  });
}

export function useInboxes() {
  return useQuery({
    queryKey: ["inboxes"],
    queryFn: mailApi.listInboxes,
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

