export interface CatboxUploadResponse {
  url: string;
  filename: string;
  size: number;
  type: string;
}

export async function uploadToCatbox(
  file: File,
  onProgress?: (percent: number) => void
): Promise<CatboxUploadResponse> {
  const {
    public: { apiBase },
  } = useRuntimeConfig();
  const endpoint = `${apiBase.replace(/\/$/, "")}/api/uploads/catbox`;
  const formData = new FormData();
  formData.append("file", file, file.name);

  const responseData = await new Promise<{
    url: string;
    filename: string;
    mimetype: string;
    size_bytes: number;
  }>((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open("POST", endpoint);
    xhr.responseType = "json";
    xhr.withCredentials = true;

    xhr.upload.onprogress = (event) => {
      if (!onProgress) return;
      if (event.lengthComputable) {
        const percent = Math.round((event.loaded / event.total) * 100);
        onProgress(percent);
      } else {
        onProgress(0);
      }
    };

    xhr.onerror = () => {
      reject(new Error("Network error while uploading attachment"));
    };

    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        const data = xhr.response ?? safeParse(xhr.responseText);
        if (data?.url) {
          resolve(data);
        } else {
          reject(new Error("Malformed response from upload endpoint"));
        }
      } else {
        let message = "Upload failed";
        if (xhr.status === 413) {
          message = "File exceeds the 20MB limit.";
        } else if (typeof xhr.responseText === "string" && xhr.responseText.trim().length) {
          message = xhr.responseText.trim();
        }
        reject(new Error(message));
      }
    };

    xhr.send(formData);
  });

  if (onProgress) {
    onProgress(100);
  }

  return {
    url: responseData.url,
    filename: responseData.filename ?? file.name,
    size: responseData.size_bytes ?? file.size,
    type: responseData.mimetype ?? file.type,
  };
}

function safeParse(payload: unknown) {
  if (typeof payload !== "string") return null;
  try {
    return JSON.parse(payload);
  } catch {
    return null;
  }
}

