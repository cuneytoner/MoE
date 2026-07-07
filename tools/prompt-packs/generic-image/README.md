# Generic Image Prompt Pack

## Purpose

This pack contains reusable prompts for general image generation. Use it when the subject is not yet project-specific or when you need a quick visual reference, mood board, marketing-style image, or before/after concept.

## Categories

- Clean realistic object image
- Concept reference image
- Mood board style image
- Marketing visual
- Before/after idea visual

## How To Copy A Prompt Into Controlled Generation

1. Open [base-prompts.md](base-prompts.md).
2. Copy the relevant prompt text.
3. Replace `[SUBJECT]` with the exact subject.
4. Paste the final prompt into an operator-controlled generation command.
5. Record the final prompt and output path in review notes.

Do not run generation directly from this folder.

## Naming Convention

Use short lowercase filenames or prefixes that describe the subject and category:

```text
generic_object_[subject]_[timestamp]
generic_concept_[subject]_[timestamp]
generic_mood_[subject]_[timestamp]
generic_marketing_[subject]_[timestamp]
generic_before_after_[subject]_[timestamp]
```

## Review Rules

- Confirm the output is visually useful before reusing the prompt.
- Record the exact final prompt, seed, size, steps, filename, and output path.
- Treat the image as visual-only unless a deterministic source confirms details.
- Avoid generated text, fake labels, or exact dimensions.
