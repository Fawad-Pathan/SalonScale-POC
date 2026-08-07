# Technical Findings

## Recommended AI Approach

Use a stable photo-scanning workflow for the PoC. A still image gives the multimodal model enough detail to read labels and shade codes while keeping the UI simple for stylists.

## Firebase AI Logic vs Server Endpoint

Direct client-side AI access can be acceptable for a limited PoC if credentials are protected by the platform and the usage is tightly controlled. For production, a server-controlled endpoint is preferred because it protects credentials, validates requests, adds rate limiting, controls prompts, normalizes model responses, and provides audit logging.

## Security Concerns

Never ship raw model API keys in the mobile app. Treat AI output as untrusted input. Validate JSON, enforce field types, cap quantities, reject malformed responses, and run local catalogue matching before saving.

## Cost Considerations

Photo-based scans are cheaper and more predictable than continuous video analysis. Production should resize images, cache catalogue context, log token/image costs per salon, and add limits per user or salon.

## Accuracy Limitations

Similar packaging and shade-code-only differences are the main risk. Low lighting, glare, partial labels, and occluded rows will reduce accuracy. The UI should require stylist review before saving.

## Matching Strategy

The model suggests detections, quantities, shade codes, and possible product IDs. Local matching then scores exact product ID, product name similarity, brand, aliases, packaging, category, and shade code. Shade code gets high weight because visually similar salon products often differ only by shade.

## Production Recommendation

Keep the app as a capture and review client. Send images to a server endpoint that authenticates the user, fetches the salon catalogue, calls the chosen multimodal model, validates the response, performs matching, stores audit metadata, and returns only structured results to the app.
