import { Router } from "express";
import swaggerUi from "swagger-ui-express";
import path from "path";
import fs from "fs";

const docsRouter = Router();

const swaggerPath = path.resolve(__dirname, "..", "..", "swagger.json");

let swaggerDocument: unknown;
try {
  const fileContents = fs.readFileSync(swaggerPath, "utf-8");
  swaggerDocument = JSON.parse(fileContents);
} catch (error) {
  console.error("Failed to read swagger.json. Ensure it exists at project root.", error);
  swaggerDocument = {
    openapi: "3.0.0",
    info: {
      title: "Free-mail API",
      version: "unavailable",
      description: "Unable to load swagger.json. Check server logs."
    },
    paths: {}
  };
}

docsRouter.get("/swagger.json", (_req, res) => {
  res.setHeader("Content-Type", "application/json");
  res.send(swaggerDocument);
});

docsRouter.use(
  "/",
  swaggerUi.serve,
  swaggerUi.setup(swaggerDocument, {
    explorer: true,
    customSiteTitle: "Free-mail API Docs",
    swaggerOptions: {
      url: "/docs/swagger.json"
    }
  })
);

export { docsRouter };


