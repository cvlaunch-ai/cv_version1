# Dialogs, Modals, Tables, and PDF Preview Responsiveness Audit

This document reviews the Flutter frontend components of DocForge AI, focusing on overlay modals, tables, and PDF document previews, establishing formatting standards for future enhancements.

---

## 1. Summary of Audited Components

| UI Component | Current Implementation | Responsiveness Status | Recommendations / Notes |
| :--- | :--- | :--- | :--- |
| **Dialogs & Modals** | None present in the active routes. | **PASSED (By Design)** | All features operate inline or through sliding drawers. |
| **Tables & Grids** | None present. | **PASSED (By Design)** | Grid tool cards adapt dynamically via LayoutBuilder. |
| **PDF Previews** | Monospaced Text/Markdown editor container. | **PASSED (Responsive Reflow)** | Text-based rendering wraps and adapts perfectly to all screen widths. |

---

## 2. Component Analysis & Hardening Design Systems

### 2.1 Dialogs & Modals (Future Hardening Guidelines)
Since dialogs can easily break on small Mobile screens (clipping buttons) or look awkward on Desktop (stretching full screen), any future modals must adhere to the following design system:

1. **No Fixed Widths/Heights**:
   - Never specify `width: 400` or `height: 500`.
   - Wrap dialog content in `ConstrainedBox` using screen-relative maximum constraints:
     ```dart
     showDialog(
       context: context,
       builder: (context) => Dialog(
         insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
         child: ConstrainedBox(
           constraints: BoxConstraints(
             maxWidth: 600, // Safe limit for Desktop
             maxHeight: MediaQuery.of(context).size.height * 0.8, // Safe vertical limit
           ),
           child: DialogContent(),
         ),
       ),
     );
     ```
2. **Mobile Screen Switches**:
   - On Desktop/Tablet: Show centered dialog card modals.
   - On Mobile: Convert to a bottom sheet modal (`showModalBottomSheet`) to provide a native mobile feel.

### 2.2 Table Responsiveness (Future Hardening Guidelines)
If tabular listings (e.g. processed document logs, billing history) are introduced:
1. **Horizontal Scroll Wrapper**:
   - Wrap `DataTable` in a horizontal `SingleChildScrollView` to prevent pixel overflows on narrow screens:
     ```dart
     SingleChildScrollView(
       scrollDirection: Axis.horizontal,
       child: DataTable(
         columns: [ ... ],
         rows: [ ... ],
       ),
     )
     ```
2. **Card Folding Pattern**:
   - On Mobile, convert tables into a `ListView` of custom cards to ensure data remains readable without horizontal panning.

### 2.3 PDF Preview Rendering (Responsive Audit)
- **Current Pattern**:
  - Previews are displayed using a standard scrollable, monospaced text box inside a card container (such as in `ResumeGeneratorScreen` and `CoverLetterGeneratorScreen`).
  - *Responsive Rating*: **10 / 10**. Because it renders text, the browser automatically reflows lines on mobile screens (320px) without forcing horizontal panning or microscopic zooming.
- **Graphic PDF Viewer Guidelines (If added in the future)**:
  - If a true graphic PDF viewer (e.g., displaying exact printable pages) is integrated, it must be wrapped in an `InteractiveViewer` with scale constraints to allow pinch-to-zoom and pan on mobile devices:
    ```dart
    InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: PdfPageViewWidget(),
    )
    ```
