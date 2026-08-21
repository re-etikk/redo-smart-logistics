// Consistent error envelope (spec §57). Never leak stack traces to clients.
export function errorHandler(err, req, res, _next) {
  console.error("[api]", req.method, req.path, err);
  const status = err.status || 500;
  res.status(status).json({
    error: err.code || "INTERNAL_ERROR",
    message: err.publicMessage || "Something went wrong. Please try again.",
  });
}

export const apiError = (status, code, publicMessage) =>
  Object.assign(new Error(code), { status, code, publicMessage });
