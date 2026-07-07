# 62 Negative Prompt Notes

This note documents phrases that may help avoid unwanted style in future image runs.

## What Negative Prompting Means In This Project

A negative prompt is text that tells the image workflow what to avoid.

In this project, negative prompt use is optional and depends on workflow support. Do not assume a negative prompt field is active unless the workflow explicitly supports it.

## Flux Schnell Workflow Caution

Flux Schnell may respond differently depending on the ComfyUI workflow and node support.

If the current workflow does not expose a negative prompt input, do not edit workflow JSON casually just to add one. Treat negative prompt support as a reviewed future workflow change.

## Avoid Luxury Resort Style

Avoid outputs that look like hotel, resort, or luxury marketing images when the goal is a practical backyard build.

Candidate phrase:

```text
luxury resort
```

## Avoid Fantasy Architecture

Avoid impossible or fantasy structures when the goal is buildable pergola reference.

Candidate phrase:

```text
fantasy
```

## Avoid Impossible Joinery

Avoid outputs with impossible beam/post connections or unrealistic structural details.

Candidate phrase:

```text
impossible structure
```

## Avoid Glossy Showroom Render

Avoid overly polished render-style images when the goal is practical documentation.

Candidate phrase:

```text
glossy render
```

## Avoid Oversized Beams Unless Requested

Avoid heavy oversized timber proportions unless intentionally testing a massive-frame design.

Candidate phrase:

```text
oversized beams
```

## Avoid Open Pergola Roof If Covered Roof Is Needed

If the goal is rain protection, avoid open-roof pergola interpretations.

Candidate phrase:

```text
open roof
```

## Candidate Negative Phrases

- luxury resort
- fantasy
- impossible structure
- glossy render
- oversized beams
- open roof
- decorative only
- no practical construction details
