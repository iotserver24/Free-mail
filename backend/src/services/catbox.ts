import axios from "axios";
import FormData from "form-data";
import { config } from "../config";

export async function uploadBufferToCatbox(fileName: string, buffer: Buffer) {
  const form = new FormData();
  form.append("reqtype", "fileupload");
  form.append("fileToUpload", buffer, {
    filename: fileName,
  });

  const response = await axios.post(config.catbox.apiUrl, form, {
    headers: form.getHeaders(),
  });

  if (typeof response.data === "string" && response.data.startsWith("https://")) {
    return response.data.trim();
  }

  throw new Error(`Catbox upload failed: ${response.data}`);
}

