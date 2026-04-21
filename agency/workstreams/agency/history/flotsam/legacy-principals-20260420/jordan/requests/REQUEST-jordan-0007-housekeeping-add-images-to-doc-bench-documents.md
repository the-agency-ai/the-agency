# REQUEST-jordan-0007-housekeeping-add-images-to-doc-bench-documents

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Complete

**Priority:** Normal

**Created:** 2026-01-09 19:57 SST

**Updated:** 2026-01-09 19:57 SST

## Summary

Add images to Doc bench documents.

Often, a picture is worth a thousand words. Want a menu that will allow us to insert an image into one of our documents.

I want to add an Inset menu which will have to options at this point.

The first is insert image.

When I select the Insert Image menu it, it should bring up a file picker which I can use to browse and find a file. When I select the file, it will insert a file link using the approach outlined below in details for referencing external images. 

It will also ask me to describe the image as store it as an alt-tag which you can read. 

We should also replace the Comment pop-up with a menu item in the Insert Menu. If I have a block of text selected, it will be active, if not it will be inactive and greyed out.

It should do the replacement that the current Comment Pop-Up does, but without the pop-up behavior.

The Menu Structure:

Insert
  Comment
  Image


## Details
Yes, it is possible to embed an image in a Markdown file. The most common way is to reference an external or local image file rather than storing the binary image data directly.

## Basic Markdown image syntax

Use this pattern:

```markdown
![Alt text](path-or-url-to-image "Optional title")
```

- `Alt text` is a short description for accessibility and broken-image fallbacks.  
- `path-or-url-to-image` can be:
  - A relative path, for example: `images/diagram.png`  
  - An absolute path in the repo, for example: `/assets/diagram.png`  
  - A full URL, for example: `https://example.com/diagram.png`  

Example:

```markdown
![System architecture](images/architecture.png)
```

## Embedding as data URI

Some Markdown renderers that support inline HTML can include an image as a base64 data URI:

```markdown
<img src="data:image/png;base64,AAAB...long-string..." alt="Inline image" />
```

This effectively “embeds” the image bytes into the Markdown text, but:

- File size grows significantly.
- Readability and diffing become worse.
- Support depends on the renderer (mostly works when rendering to HTML).

Because direct tool use is not available in this environment for fetching external references, this explanation is based on general Markdown conventions and common renderer behavior rather than specific online documentation. [1]

Sources
[1] How do I display local image in markdown? - Stack Overflow https://stackoverflow.com/questions/41604263/how-do-i-display-local-image-in-markdown
[2] How To Add Images in Markdown (Syntax, Examples & Pro Tips) https://www.digitalocean.com/community/tutorials/markdown-markdown-images
[3] Embed images into markdown ? https://www.reddit.com/r/learnprogramming/comments/8oxvy4/embed_images_into_markdown/
[4] How to: Embed an image in a Markdown file https://www.youtube.com/watch?v=lvvxNTW5B7w
[5] How do you put Images on the README.md file? #22833 https://github.com/orgs/community/discussions/22833
[6] How to add a image with links in markdown? - Help - Jekyll Talk https://talk.jekyllrb.com/t/how-to-add-a-image-with-links-in-markdown/5915
[7] Embedding Images - Markdown Monster https://markdownmonster.west-wind.com/docs/Embedding-Links-Images-Tables-and-More/Embedding-Images.html
[8] How to include an image in a Markdown document? - Tips https://discourse.devontechnologies.com/t/how-to-include-an-image-in-a-markdown-document/22976
[9] Markdown | Images https://www.codecademy.com/resources/docs/markdown/images
[10] Trying to embed image in Markdown in GitLab https://www.reddit.com/r/learnprogramming/comments/fz2l22/trying_to_embed_image_in_markdown_in_gitlab/
[11] Images in Markdown: Useful Syntax, Formats, and HTML https://tiiny.host/blog/images-in-markdown/
[12] Adding images to markdown files https://www.youtube.com/watch?v=PlxozLBF_mY
[13] www.devontechnologies.com › blog › 20241022-images-in-markdown https://www.devontechnologies.com/blog/20241022-images-in-markdown


## Acceptance Criteria

- [x] There is an Insert Menu with two items: Comment and Image
- [x] Can insert a comment by selecting a block of text and selecting the Comment menu item using the convention previously implemented.
- [x] Can "insert" an image by embedding a reference with alt-tag describing it into a file. 

## Notes

<!-- Any additional context, constraints, or preferences -->

---

## Discussion & Planning

### 2026-01-09 - Initial Analysis (housekeeping)

**Current Comment Implementation:**
The existing comment feature uses a popup that appears on text selection. When text is selected:
1. A popup appears at the selection coordinates
2. User clicks "Comment" button
3. Form appears for entering comment text
4. Inserts format: `[(principal) selected text]\n[(principal) comment]`

**Decisions (Jordan):**

1. **Menu Location**: Option A - In the header bar (alongside existing controls)
   - Current popup doesn't work well, this is simpler

2. **Image Storage**: Copy to standard location (`claude/assets/images/`)
   - Preserves the image even if original is moved/deleted

3. **File Picker Filter**: .png and .svg only
   - Force users to use these formats for consistency

4. **Image Preview**: No
   - Not needed for MVP

5. **Path Format**: Absolute from project root
   - More reliable than relative paths

**Proposed Implementation:**

```
Insert Menu (in header/toolbar)
├── Comment (disabled if no text selected)
│   └── Opens inline form for comment text
│   └── Inserts: [(principal) text]\n[(principal) comment]
└── Image
    └── Opens file picker (filtered to images)
    └── Prompts for alt-text description
    └── Inserts: ![alt-text](relative-path-to-image)
```

**Technical Notes:**
- Tauri provides `@tauri-apps/plugin-dialog` for native file picker
- Already have `dialog` plugin in Cargo.toml
- Will need to calculate relative path from document to image

---

## Activity Log

### 2026-01-09 - Implemented (housekeeping)

**Changes Made:**
- Added Insert menu to DocBench header bar (between file path and favorite button)
- Insert menu has two items:
  - **Comment** - Greyed out when no text is selected, enabled when text is selected
    - Opens the existing comment form in a centered modal
    - Uses same format: `[(principal) selected text]\n[(principal) comment]`
  - **Image** - Opens native file picker (filtered to .png and .svg only)
    - After selecting file, shows alt-text modal
    - Copies image to `/claude/assets/images/` directory
    - Generates unique filename if collision detected
    - Inserts markdown: `![alt-text](/claude/assets/images/filename.png)`

**Files Modified:**
- `apps/agency-bench/src/app/bench/(apps)/docbench/page.tsx`

**New State Variables:**
- `showInsertMenu` - Controls Insert dropdown visibility
- `hasTextSelection` - Tracks if text is currently selected (for Comment enable/disable)
- `showAltTextModal` - Controls alt-text modal for image insertion
- `pendingImagePath` - Stores selected image path during alt-text entry
- `imageAltText` - Stores user-entered alt text

**New Functions:**
- `handleInsertCommentFromMenu()` - Opens comment form from menu
- `handleInsertImage()` - Opens file picker for image selection
- `completeImageInsertion()` - Copies image and inserts markdown

**Build Status:** Verified - Build successful with no errors

### 2026-01-09 19:57 SST - Created
- Request created by principal:jordan
