# Discovery Questions

Comprehensive question bank for gathering feature requirements. Use these to ensure nothing is missed during planning.

---

## Core Questions (Always Ask)

### 1. Overview

```
□ What is the feature name? (snake_case for folder)
□ What does it do in one sentence?
□ Who uses this feature? (user type)
□ What problem does it solve?
□ What's the minimum viable version?
```

### 2. Domain Model

```
□ What are the main entities/objects?
□ For each entity:
  □ What fields does it have?
  □ Which fields are required vs optional?
  □ What are the data types?
  □ Are there any enums?
  □ Any computed/derived properties?
  □ Any relationships to other entities?
□ What business rules apply?
□ Any validation rules?
```

### 3. Data Sources

```
□ Where does data come from? (check all that apply)
  □ REST API
  □ Supabase
  □ GraphQL
  □ Local storage (SharedPrefs)
  □ Secure storage (PII, tokens)
  □ SQLite / Local database
  □ Camera
  □ Photo gallery
  □ Location / GPS
  □ Bluetooth / Sensors
  □ Files / Documents
  □ Other: ___________

□ For API sources:
  □ What endpoints exist?
  □ What's the request/response format?
  □ Any authentication required?
  □ Any rate limits?

□ For local storage:
  □ What needs to persist across sessions?
  □ What's sensitive (needs secure storage)?
```

### 4. Screens & Navigation

```
□ What screens are needed?
□ For each screen:
  □ What's the purpose?
  □ What data does it display?
  □ What actions can user take?
  □ How does user get here?
  □ Where can user go from here?
□ What's the navigation flow?
□ Any modals or bottom sheets?
□ Any tab navigation within feature?
```

### 5. User Actions

```
□ What can the user CREATE?
□ What can the user READ/VIEW?
□ What can the user UPDATE/EDIT?
□ What can the user DELETE?
□ Any other actions? (share, export, etc.)
□ For each action:
  □ What triggers it?
  □ What's the success outcome?
  □ What's the failure outcome?
  □ Any confirmation needed?
```

---

## Feature-Type Specific Questions

### For List/Collection Features

```
□ How are items displayed? (list, grid, cards)
□ How are items sorted? (date, name, custom)
□ Can user change sort order?
□ Is there search/filter capability?
□ Is there pagination or infinite scroll?
□ What happens when list is empty?
□ Can user reorder items?
□ Can user select multiple items?
□ Are there bulk actions?
```

### For Form/Input Features

```
□ What fields are in the form?
□ For each field:
  □ Input type (text, number, date, etc.)
  □ Required or optional?
  □ Validation rules?
  □ Placeholder/hint text?
  □ Error messages?
□ When is validation triggered? (on blur, on submit)
□ Auto-save or manual save?
□ Warn about unsaved changes?
□ Pre-fill any fields?
```

### For Media Features (Camera/Gallery/Audio)

```
□ What media types? (photo, video, audio)
□ Capture new or select existing or both?
□ Any size/quality limits?
□ Compression needed?
□ Where is media stored? (local, cloud)
□ Generate thumbnails?
□ Allow editing/cropping?
□ Multiple selection allowed?
```

### For Location Features

```
□ How precise? (exact, city, region)
□ One-time or continuous tracking?
□ Background location needed?
□ Show on map?
□ Geocoding needed? (coordinates ↔ address)
□ Privacy considerations?
```

### For Social/Sharing Features

```
□ What can be shared?
□ Share to where? (native share sheet, in-app, specific platforms)
□ Can users comment/react?
□ Privacy settings? (public, private, friends-only)
□ Notifications for interactions?
```

### For Settings/Preferences Features

```
□ What settings are available?
□ For each setting:
  □ Type (toggle, select, input)
  □ Default value?
  □ Affects what behavior?
□ Settings stored where? (local, server)
□ Sync across devices?
□ Reset to defaults option?
```

---

## Edge Cases & Error Handling

### Always Consider

```
□ What if network is unavailable?
  □ Show cached data?
  □ Queue for later?
  □ Block action?

□ What if data is empty?
  □ Empty state message?
  □ CTA to create first item?

□ What if action fails?
  □ Error message?
  □ Retry option?
  □ Rollback changes?

□ What if user cancels mid-action?
  □ Save draft?
  □ Discard?
  □ Ask user?

□ What if data is stale?
  □ Auto-refresh?
  □ Show "last updated" time?
  □ Pull-to-refresh?
```

### For Long-Running Operations

```
□ Show progress indicator?
□ Can user cancel?
□ Continue in background?
□ What if app is killed mid-operation?
```

### For Destructive Actions

```
□ Confirmation required?
□ Undo available?
□ Soft delete or hard delete?
□ Cascade to related data?
```

---

## Offline & Sync

```
□ Does this feature need offline support?

If yes:
□ What should work offline?
  □ Read existing data
  □ Create new items
  □ Edit existing items
  □ Delete items
□ How is data synced?
  □ Auto-sync when online
  □ Manual sync button
  □ Background sync
□ Conflict resolution?
  □ Last-write-wins
  □ Server-wins
  □ Merge
  □ Ask user
□ Sync status indicators?
  □ Pending badge
  □ Failed badge
  □ Last synced time
```

---

## Performance Considerations

```
□ How much data is expected?
  □ Tens of items
  □ Hundreds of items
  □ Thousands of items
  □ Millions of items

□ Based on volume:
  □ Pagination needed?
  □ Caching needed?
  □ Lazy loading needed?
  □ Virtualization needed?

□ Any heavy operations?
  □ Image processing
  □ Large file uploads
  □ Complex calculations
  □ Consider background processing
```

---

## Accessibility Questions

```
□ All interactive elements labeled?
□ Focus order matches visual order?
□ Works with screen reader?
□ Sufficient color contrast?
□ Touch targets at least 48dp?
□ Animations respect reduced motion?
□ Error messages announced to screen reader?
```

---

## Quick Question Templates

### For CRUD Features

> What entity? What fields? What can users do with it (create, view, edit, delete)? Where is it stored?

### For List Features

> What items? How sorted? Search/filter? Pagination? Empty state?

### For Form Features

> What fields? What validation? When to validate? Auto-save?

### For Media Features

> Capture or select? What types? Size limits? Where stored?

### For Settings Features

> What settings? What types (toggle/select/input)? Where stored?

---

## Conversation Flow Example

```
Claude: What feature would you like to plan?

User: A tasks feature

Claude: Got it - a tasks feature. Let me understand this better:

1. What fields does a Task have?
   (e.g., title, description, due date, priority, status)

2. Where will tasks be stored?
   □ Local only (device storage)
   □ Cloud (Supabase/API)
   □ Both (sync)

3. What screens do you need?
   □ Task list
   □ Task detail
   □ Create/edit form
   □ Other: ___

4. Any special requirements?
   □ Due date reminders
   □ Recurring tasks
   □ Categories/tags
   □ Subtasks
   □ Other: ___

User: Title, description, due date, priority. Supabase. List and form screens. No reminders for now.

Claude: Perfect. A few more questions:

5. For priority - is that an enum (low/medium/high) or a number?

6. For the list - how should tasks be sorted by default?

7. Can users mark tasks as complete? What happens then - hide, strike-through, move to bottom?

8. Empty state - what message when no tasks?

...
```

---

## Checklist Before Finalizing

Before creating the spec, verify:

```
□ Feature name and purpose are clear
□ All entities defined with fields and types
□ All data sources identified
□ All screens listed with their purpose
□ Navigation flow is complete
□ All user actions mapped
□ Success and error states handled
□ Empty states defined
□ Offline behavior decided (even if "not supported")
□ No open questions (or documented as pending)
```
