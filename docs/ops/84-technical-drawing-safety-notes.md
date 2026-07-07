# 84 Technical Drawing Safety Notes

AI drawings are visual communication only.

They are not engineering drawings, static calculations, material approvals, or validated build plans.

## Do Not Trust Without Checking

- Do not trust AI-generated dimensions without checking.
- Do not trust AI-generated bracket geometry without checking.
- Do not trust AI-generated load path.
- Do not trust AI-generated post spacing.
- Do not trust AI-generated screw, bolt, washer, or anchor placement.
- Do not trust AI-generated roof slope, drainage, flashing, or waterproofing details.

## Use Generated Drawings For Intent

Use generated drawings to explain:

- desired wall-side pergola shape
- rough elevation/plan view intent
- covered roof intent
- where connection details are needed
- what kind of usta discussion is needed

## Real Build Still Needs

- measured site dimensions
- material list
- cut list
- connection schedule
- real screw/bolt sizes
- weatherproofing detail
- drainage direction
- structural sanity review

## Git Safety

Never commit generated drawing image binaries to Git.

Record:

- prompt ID
- output path
- output filename
- file size
- review notes

Keep generated images under runtime or an external archive, not in the source repo.
