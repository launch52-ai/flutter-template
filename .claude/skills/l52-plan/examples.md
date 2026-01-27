# Plan Examples

Complete example of planning a feature from start to finish.

---

## Example: "Memories" Feature

### Discovery Conversation

**Claude:** What feature would you like to plan?

**User:** A memories feature where users can capture photos, add captions, and view them later.

**Claude:** Let me understand this better:

1. **What screens do you need?**

   **User:** A list showing all memories, a detail view for each memory, and a way to create new ones with camera or gallery.

2. **What fields does a Memory have?**

   **User:** Photo, caption, maybe location, and when it was created.

3. **Where does the data come from?**

   **User:** Camera for capturing, gallery for picking existing photos, Supabase for storage and database.

4. **Any offline requirements?**

   **User:** Yes, users should be able to create memories offline and sync when connected.

5. **What actions can users take?**

   **User:** Create memory (camera or gallery), view memory, edit caption, delete memory, retry failed uploads.

---

### Generated Specification

```markdown
# Feature Specification: Memories

> **Status:** Ready for Implementation
> **Created:** 2025-01-12
> **Last Updated:** 2025-01-12

---

## 1. Overview

### 1.1 Purpose
Memories allows users to capture and preserve photo moments with captions and optional location data. Photos can be taken with the camera or selected from the gallery, then synced to cloud storage for backup and cross-device access.

### 1.2 User Stories
- As a user, I want to capture a photo memory so that I can preserve the moment
- As a user, I want to add a caption to my memory so that I remember the context
- As a user, I want to view my memories in a grid so that I can browse through them
- As a user, I want to create memories offline so that I don't lose moments when without internet

### 1.3 Scope
**In Scope:**
- Photo capture via camera
- Photo selection from gallery
- Caption editing
- Location tagging (optional)
- Cloud sync to Supabase
- Offline creation with background sync

**Out of Scope:**
- Video capture
- Photo editing/filters
- Sharing to social media
- Albums/organization

---

## 2. Domain Layer

### 2.1 Entities

#### Memory

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | ✓ | UUID, generated client-side |
| localPath | String? | | Local file path (before upload) |
| remoteUrl | String? | | Supabase Storage URL (after upload) |
| caption | String? | | User-provided description |
| location | LatLng? | | GPS coordinates when captured |
| syncStatus | SyncStatus | ✓ | Current sync state |
| createdAt | DateTime | ✓ | When memory was created |
| updatedAt | DateTime? | | Last modification time |

**Computed Properties:**
- `photoPath`: Returns `remoteUrl` if synced, otherwise `localPath`
- `isSynced`: Returns `syncStatus == SyncStatus.synced`
- `needsSync`: Returns `syncStatus == SyncStatus.pending || syncStatus == SyncStatus.failed`

**Business Rules:**
- Memory must have either `localPath` or `remoteUrl` (at least one)
- `syncStatus` starts as `pending` for new memories
- Caption is optional but limited to 500 characters

#### LatLng

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| latitude | double | ✓ | GPS latitude |
| longitude | double | ✓ | GPS longitude |

### 2.2 Enums

#### SyncStatus

| Value | Description |
|-------|-------------|
| pending | Created locally, awaiting upload |
| uploading | Currently uploading to cloud |
| synced | Successfully uploaded |
| failed | Upload failed, retry available |

### 2.3 Repository Interface

```dart
abstract interface class MemoriesRepository {
  /// Get all memories, ordered by creation date (newest first).
  Future<List<Memory>> getAll();

  /// Get a single memory by ID.
  Future<Memory?> getById(String id);

  /// Create a new memory from a captured/selected photo.
  ///
  /// Parameters:
  /// - [localPath]: Path to the local photo file
  /// - [caption]: Optional caption text
  /// - [location]: Optional GPS coordinates
  ///
  /// Returns the created memory with [SyncStatus.pending].
  Future<Memory> create({
    required String localPath,
    String? caption,
    LatLng? location,
  });

  /// Update a memory's caption.
  Future<Memory> updateCaption({
    required String id,
    required String caption,
  });

  /// Delete a memory (local and remote).
  Future<void> delete(String id);

  /// Get all memories pending sync.
  Future<List<Memory>> getPendingSync();

  /// Sync a single memory to cloud storage.
  ///
  /// Uploads photo to Supabase Storage, creates DB record,
  /// updates local memory with remote URL and synced status.
  Future<Memory> syncMemory(String id);

  /// Sync all pending memories.
  ///
  /// Returns list of IDs that failed to sync.
  Future<List<String>> syncAll();
}
```

---

## 3. Data Layer

### 3.1 Data Sources

| Source | Type | Operations Needed |
|--------|------|-------------------|
| Camera | ImagePicker | Capture photo → file path |
| Gallery | ImagePicker | Pick photo → file path |
| Supabase Storage | supabase_flutter | Upload, download, delete photos |
| Supabase Database | supabase_flutter | CRUD for memory records |
| Local Queue | SharedPreferences | Pending sync tracking |

> **Note:** Detailed schema, DTOs, and mappings handled by `/api` skill.

### 3.2 Local Storage (if offline support)

| What | Storage Type | Notes |
|------|--------------|-------|
| Pending sync queue | SharedPreferences | List of memory IDs awaiting sync |
| Local memory data | SharedPreferences | Memory data before sync completes |

### 3.3 Offline Strategy

| Operation | Offline Behavior |
|-----------|------------------|
| Create | Save locally with SyncStatus.pending |
| Read | Merge local + synced data |
| Update | Update local, re-sync if already synced |
| Delete | Delete local, queue remote delete |
| Sync | Process pending queue when online |

---

## 4. Presentation Layer

### 4.1 Screens

#### MemoriesListScreen

**Route:** `/memories`

**Purpose:** Display all user's memories for browsing.

**Data Displayed:**
- List of Memory items showing:
  - Photo thumbnail
  - Sync status indicator (pending/failed/synced)
- Aggregate info: pending count, failed count

**Required States:**
- Loading (initial fetch)
- Loaded (with memories)
- Empty (no memories yet)
- Error (fetch failed)

**User Actions:**
| Action | Result |
|--------|--------|
| View memory | Navigate to detail screen |
| Create new | Navigate to create flow |
| Refresh | Reload from local + remote |
| Manual sync all | Sync all pending memories |
| Retry single | Retry failed memory sync |
| Delete | Confirm → Remove memory |

**Notes for Design:**
- Sync status must be clearly visible on each item (pending vs failed vs synced)
- Should handle 100+ memories efficiently
- Failed items need obvious "retry" affordance

#### MemoryDetailScreen

**Route:** `/memories/:id`

**Purpose:** Display single memory with full details and actions.

**Data Displayed:**
- Full-size photo (zoomable)
- Caption (if set)
- Location (if captured)
- Date created
- Sync status

**Required States:**
- Loading
- Loaded
- Error
- Not found

**User Actions:**
| Action | Result |
|--------|--------|
| Edit caption | Update caption (inline or modal) |
| Delete | Confirm → Delete → Navigate back |
| Retry sync | Attempt sync if failed |

**Notes for Design:**
- Photo should be primary focus, zoomable
- Caption may be multiple lines
- Location and date are secondary info

#### CreateMemoryScreen

**Route:** `/memories/create`

**Purpose:** Capture or select photo and create new memory.

**Two-Step Flow:**
1. **Source selection**: Choose camera or gallery
2. **Details**: Preview photo, add caption, toggle location

**Form Fields:**
| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| photo | image | ✓ | Must select | From camera or gallery |
| caption | text | | Max 500 chars | Multiline |
| includeLocation | toggle | | | Requests permission if enabled |

**Required States:**
- Initial (source selection)
- Photo selected (showing preview + form)
- Saving
- Success
- Error

**User Actions:**
| Action | Result |
|--------|--------|
| Capture photo | Open camera → Return with photo |
| Pick from gallery | Open gallery → Return with photo |
| Save | Validate → Create memory → Navigate to list |
| Cancel | Warn if photo selected → Navigate back |

**Notes for Design:**
- Clear choice between camera and gallery
- Photo preview should be prominent before saving
- Caption is optional - don't make it feel required

### 4.2 States

#### MemoriesListState

```dart
@freezed
sealed class MemoriesListState with _$MemoriesListState {
  const factory MemoriesListState.initial() = MemoriesListStateInitial;
  const factory MemoriesListState.loading() = MemoriesListStateLoading;
  const factory MemoriesListState.loaded({
    required List<Memory> items,
    @Default(false) bool isSyncing,
    @Default(0) int pendingCount,
    @Default(0) int failedCount,
  }) = MemoriesListStateLoaded;
  const factory MemoriesListState.error(String message) = MemoriesListStateError;
}
```

#### MemoryDetailState

```dart
@freezed
sealed class MemoryDetailState with _$MemoryDetailState {
  const factory MemoryDetailState.loading() = MemoryDetailStateLoading;
  const factory MemoryDetailState.loaded({
    required Memory memory,
    @Default(false) bool isSyncing,
  }) = MemoryDetailStateLoaded;
  const factory MemoryDetailState.error(String message) = MemoryDetailStateError;
  const factory MemoryDetailState.deleted() = MemoryDetailStateDeleted;
}
```

#### CreateMemoryState

```dart
@freezed
sealed class CreateMemoryState with _$CreateMemoryState {
  const factory CreateMemoryState.initial() = CreateMemoryStateInitial;
  const factory CreateMemoryState.photoSelected({
    required String localPath,
    String? caption,
    @Default(false) bool includeLocation,
  }) = CreateMemoryStatePhotoSelected;
  const factory CreateMemoryState.saving() = CreateMemoryStateSaving;
  const factory CreateMemoryState.success(Memory memory) = CreateMemoryStateSuccess;
  const factory CreateMemoryState.error(String message) = CreateMemoryStateError;
}
```

### 4.3 Providers

#### MemoriesListNotifier

| Method | Description | State Transitions |
|--------|-------------|-------------------|
| `build()` | Load all memories | initial → loading → loaded/error |
| `refresh()` | Reload from sources | loaded → loading → loaded |
| `syncAll()` | Sync pending memories | loaded(isSyncing: true) → loaded |
| `retrySync(id)` | Retry single memory | Updates item in list |
| `delete(id)` | Delete memory | Optimistic remove from list |

#### MemoryDetailNotifier

| Method | Description | State Transitions |
|--------|-------------|-------------------|
| `build(id)` | Load memory by ID | loading → loaded/error |
| `updateCaption(caption)` | Edit caption | loaded → saving → loaded |
| `delete()` | Delete memory | loaded → deleted |
| `syncNow()` | Force sync | loaded(isSyncing: true) → loaded |

#### CreateMemoryNotifier

| Method | Description | State Transitions |
|--------|-------------|-------------------|
| `build()` | Initialize | initial |
| `capturePhoto()` | Open camera | initial → photoSelected/initial |
| `pickFromGallery()` | Open gallery | initial → photoSelected/initial |
| `setCaption(text)` | Update caption | photoSelected (updated) |
| `toggleLocation()` | Toggle location | photoSelected (updated) |
| `save()` | Create memory | photoSelected → saving → success/error |
| `reset()` | Clear selection | → initial |

---

## 5. User Flows

### 5.1 Create Memory Flow

**Happy Path:**
1. User initiates create from list screen
2. User chooses source (camera or gallery)
3. User captures/selects photo
4. User optionally adds caption and location toggle
5. User saves
6. Memory created with status `pending` → Return to list

**Cancel Path:**
- If no photo selected: Return immediately
- If photo selected: Confirm discard → Return to list

**Error Path:**
- Camera/gallery permission denied → Show permission explanation
- Save fails → Show error, keep form data for retry

### 5.2 Offline Sync Flow

**Create While Offline:**
1. User creates memory normally
2. Memory saved locally with status: `pending`
3. User sees pending indicator on item in list

**When Network Restored:**
1. Sync service detects connectivity
2. For each pending memory:
   - Update status to `uploading`
   - Upload photo to Supabase Storage
   - Create database record
   - On success: status → `synced`, store remote URL
   - On failure: status → `failed`
3. User can manually retry failed items

**Sync Status States:**
- `pending` → Waiting for network
- `uploading` → Currently uploading
- `synced` → Successfully uploaded
- `failed` → Upload failed, retry available

---

## 6. Error Handling

### 6.1 Error Types & Recovery

| Error Type | Recovery Action |
|------------|-----------------|
| Camera permission denied | Open settings |
| Gallery permission denied | Open settings |
| Storage full | None (inform user) |
| Upload failed | Retry option |
| Network unavailable | Auto-retry when online |
| Load failed | Retry option |

### 6.2 Empty States

| State | Recovery Action |
|-------|-----------------|
| No memories | CTA to create first |
| All synced | None (positive feedback) |

> **Note:** Actual messages handled by `/i18n`, accessibility labels by `/a11y`.

---

## 7. Implementation Order

| Step | Skill | Command | Creates | Depends On |
|------|-------|---------|---------|------------|
| 1 | domain | `/domain memories` | Memory, LatLng, SyncStatus, MemoriesRepository | - |
| 2 | data | `/data memories --source=camera` | CameraService (ImagePicker wrapper) | 1 |
| 3 | data | `/data memories --source=supabase` | SupabaseStorageService, MemoriesRepositoryImpl | 1 |
| 4 | data | `/data memories --source=local` | LocalMemoriesCache (SharedPrefs) | 1 |
| 5 | data | `/data memories --source=sync` | SyncService (coordinates local + remote) | 1, 3, 4 |
| 6 | screen | `/screen memories list` | MemoriesListScreen, MemoriesListNotifier | 1, 5 |
| 7 | screen | `/screen memories detail` | MemoryDetailScreen, MemoryDetailNotifier | 1, 5 |
| 8 | screen | `/screen memories create` | CreateMemoryScreen, CreateMemoryNotifier | 1, 2, 5 |
| 9 | i18n | `/i18n memories` | memories.i18n.yaml with all strings | 6, 7, 8 |
| 10 | testing | `/testing memories` | Repository, provider, widget tests | All above |
| 11 | design | `/design memories` | Loading states, animations, polish | 6, 7, 8 |
| 12 | a11y | `/a11y memories` | Semantic labels, focus order | 6, 7, 8 |

---

## 8. Open Questions

| Question | Context | Decision |
|----------|---------|----------|
| Photo compression | Should we compress before upload? | **Resolved:** Yes, max 1920px, 80% JPEG quality |
| Delete behavior | Delete local only or local + remote? | **Resolved:** Both - queue remote delete for sync |
| Location precision | Exact coordinates or city-level? | **Pending:** Need to decide on privacy |

---

## 9. Technical Notes

### Dependencies Required
- `image_picker: ^1.0.0` - Camera and gallery access
- `supabase_flutter: ^2.0.0` - Storage and database
- `geolocator: ^10.0.0` - Location services (optional)
- `connectivity_plus: ^5.0.0` - Network state monitoring

### Platform Considerations
- **iOS**: Add NSCameraUsageDescription and NSPhotoLibraryUsageDescription to Info.plist
- **Android**: Add CAMERA and READ_EXTERNAL_STORAGE permissions to AndroidManifest

### Performance Considerations
- Compress images before upload (max 1920px width)
- Use thumbnail for grid view (generate on create)
- Lazy load full images in detail view
- Limit sync to 3 concurrent uploads

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2025-01-12 | Initial spec created | Claude |
```

---

## What Happens Next

After this spec is approved, run skills in order:

```bash
# Step 1: Create domain layer
/domain memories

# Step 2-5: Create data layer components
/data memories --source=camera
/data memories --source=supabase
/data memories --source=local
/data memories --source=sync

# Step 6-8: Create screens
/screen memories list
/screen memories detail
/screen memories create

# Step 9-12: Polish
/i18n memories
/testing memories
/design memories
/a11y memories
```

Each skill reads from the spec and has full context for implementation.
