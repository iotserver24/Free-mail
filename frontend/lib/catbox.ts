const CATBOX_ENDPOINT = "https://catbox.moe/user/api.php";

export interface CatboxUploadResponse {
  url: string;
  filename: string;
  size: number;
  type: string;
}

export async function uploadToCatbox(file: File): Promise<CatboxUploadResponse> {
  const { public: publicConfig } = useRuntimeConfig();
  const formData = new FormData();
  formData.append("reqtype", "fileupload");
  if (publicConfig.catboxUserHash) {
    formData.append("userhash", publicConfig.catboxUserHash);
  }
  formData.append("fileToUpload", file, file.name);

  const response = await fetch(CATBOX_ENDPOINT, {
    method: "POST",
    body: formData,
  });

  const text = (await response.text()).trim();
  if (!response.ok || text.startsWith("ERROR")) {
    throw new Error(text || "Catbox upload failed");
  }

  return {
    url: text,
    filename: file.name,
    size: file.size,
    type: file.type,
  };
}

