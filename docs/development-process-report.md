# Development Process Report

## Project Objective

Build a functional PoC that lets at least one stylist scan salon backbar products, review detected products and counts, save the scan, and ask inventory questions.

## Team Roles

- Mobile engineer: Flutter UI, camera/gallery flow, state management.
- Firebase engineer: Auth, Firestore, Storage, data model.
- AI engineer: image-analysis provider abstraction, prompt, JSON validation.
- QA/user researcher: stylist testing checklist, result review, feedback capture.

## Development Approach

The implementation prioritizes mock mode first so the app can run without paid services. AI, Firebase, and assistant features are behind interfaces so production services can be swapped in without rewriting screens.

## Weekly Milestones

- Week 1: Flutter structure, Firebase placeholders, product catalogue, recognition interface, mock recognition, technical findings.
- Week 2: Home screen, camera/gallery flow, mock scan results, editable results, history UI.
- Week 3: API image-analysis provider, strict JSON parsing, catalogue matching, confidence handling.
- Week 4: Firestore persistence, inventory updates, assistant chat, testing docs, functional PoC.

## Technical Decisions

- Riverpod is used for predictable feature-level state.
- Still-image scanning is used instead of continuous video for MVP reliability.
- Local matching validates and improves model-suggested catalogue matches.
- Mock mode remains the default until credentials are configured.

## Challenges

- Similar products can differ only by shade code.
- Mobile photos may have glare, blur, or hidden labels.
- Client-side AI credentials are not appropriate for production.
- Local test data must be realistic enough to reveal matching issues.

## Testing Process

Automated tests cover JSON parsing, shade matching, duplicate merging, mock recognition, local inventory updates, mock assistant answers, and scan-result editing. Manual stylist testing should validate that the workflow is understandable under real salon lighting.

## User Feedback Section

Capture stylist comments about scan speed, product recognition quality, count clarity, editing effort, and confidence in the saved result.

## Results

The PoC provides the complete mocked scan workflow with replaceable Firebase and AI services. It is suitable for a first stylist usability test after running on a Flutter-equipped machine.

## Limitations

Real multimodal model accuracy is not measured in this local build. Product crops and live overlays are placeholders. Voice input is not implemented.

## Next Steps

Connect a server AI endpoint, seed Firestore with the catalogue, run stylist testing, collect false positives/negatives, and tune matching weights and aliases.
