# Data Skill Examples

Examples showing data layer generation from various input sources. Code is in `reference/` directory.

---

## Quick Reference

| Input Source | Example | Reference Files |
|--------------|---------|-----------------|
| Backend code (NestJS) | Posts feature | `reference/examples/posts/` |
| Endpoint description | Tasks feature | `reference/examples/tasks/` |
| OpenAPI spec | Products feature | `reference/examples/products/` |

---

## Scenario-Based Pattern Selection

Quick reference for which pattern files to use based on your scenario.

| Scenario | Pattern Files to Use |
|----------|---------------------|
| **Basic CRUD** | `models/simple_model.dart`, `repositories/basic_repository_impl.dart` |
| **Offline-first** | `models/nested_model.dart`, `data_sources/local_data_source_prefs.dart`, `repositories/cached_repository_impl.dart` |
| **Auth feature** | `data_sources/local_data_source_secure.dart` for tokens |
| **Custom converters** | `models/custom_converter_model.dart` for UPPERCASE enums, Unix timestamps |
| **Paginated lists** | `models/paginated_response.dart`, `pagination/paginated_result.dart` |

---

## Example 1: From Backend Code (NestJS)

### Input

```typescript
// posts.controller.ts
@Controller('posts')
export class PostsController {
  @Get()
  findAll(@Query('page') page = 1, @Query('limit') limit = 20) {}

  @Get(':id')
  findOne(@Param('id') id: string) {}

  @Post()
  create(@Body() createPostDto: CreatePostDto) {}

  @Patch(':id')
  update(@Param('id') id: string, @Body() updatePostDto: UpdatePostDto) {}

  @Delete(':id')
  remove(@Param('id') id: string) {}
}

// post.entity.ts
export class Post {
  id: string;
  title: string;
  content: string;
  category_id: string | null;
  tags: string[];
  author: { id: string; name: string; avatar_url: string | null };
  created_at: Date;
  updated_at: Date | null;
}
```

### What Claude Extracts

| Item | Extracted |
|------|-----------|
| **Endpoints** | GET /posts, GET /posts/:id, POST /posts, PATCH /posts/:id, DELETE /posts/:id |
| **Field mappings** | `category_id` → `categoryId`, `created_at` → `createdAt`, `avatar_url` → `avatarUrl` |
| **Nested objects** | `author` → `PostAuthor` entity + `PostAuthorModel` DTO |
| **Pagination** | Query params `page`, `limit` → return type with `total` |

### Generated Files

```
reference/examples/posts/
├── domain/
│   ├── post.dart              # Entity with nested PostAuthor
│   └── posts_repository.dart  # Interface with CRUD methods
└── data/
    ├── post_model.dart        # DTO with @JsonKey mappings
    ├── create_post_request.dart
    ├── update_post_request.dart
    └── posts_repository_impl.dart  # Full implementation
```

---

## Example 2: From Endpoint Description

### Input

```
GET /tasks → List<Task>
GET /tasks/:id → Task
POST /tasks { title, description?, due_date?, priority } → Task
PATCH /tasks/:id { title?, description?, due_date?, priority?, status? } → Task
DELETE /tasks/:id → void

Task has:
- id: string
- title: string
- description: string?
- due_date: datetime?
- priority: enum (low, medium, high)
- status: enum (todo, in_progress, done)
- created_at: datetime
```

### What Claude Extracts

| Item | Extracted |
|------|-----------|
| **Enums** | `TaskPriority`, `TaskStatus` |
| **Optional fields** | `description`, `dueDate` nullable |
| **Computed properties** | `isOverdue`, `isCompleted` getters |

### Generated Files

```
reference/examples/tasks/
├── domain/
│   ├── task.dart              # Entity with enums and computed props
│   └── tasks_repository.dart
└── data/
    ├── task_model.dart        # @JsonKey(unknownEnumValue: ...) for enums
    └── create_task_request.dart
```

**Key pattern:** Enum handling with `@JsonKey(unknownEnumValue: TaskPriority.medium)` for graceful fallback on unknown API values.

---

## Example 3: From OpenAPI Spec

### Input

```yaml
paths:
  /products:
    get:
      parameters:
        - name: category
          in: query
          schema: { type: string }
      responses:
        200:
          content:
            application/json:
              schema:
                type: array
                items: { $ref: '#/components/schemas/Product' }

components:
  schemas:
    Product:
      type: object
      required: [id, name, price]
      properties:
        id: { type: string, format: uuid }
        name: { type: string }
        description: { type: string }
        price: { type: number, format: float }
        discount_price: { type: number, format: float }
        images: { type: array, items: { type: string, format: uri } }
        category: { $ref: '#/components/schemas/Category' }
        in_stock: { type: boolean, default: true }
        created_at: { type: string, format: date-time }
```

### What Claude Extracts

| Item | Extracted |
|------|-----------|
| **Types** | `uuid` → String, `float` → double, `date-time` → DateTime |
| **Defaults** | `in_stock: true` → `@Default(true)` |
| **Arrays** | `images` → `List<String>` with `@Default([])` |
| **Refs** | `$ref: Category` → nested `ProductCategory` |
| **Computed** | `currentPrice`, `hasDiscount`, `discountPercent` getters |

### Generated Files

```
reference/examples/products/
├── domain/
│   ├── product.dart           # Entity with business logic getters
│   └── products_repository.dart
└── data/
    └── product_model.dart     # Nested model with defaults
```

---

## Example 4: Updating Existing Feature

When adding API integration to an existing feature:

### Scenario

Feature `bookmarks` exists with basic domain layer. User wants to add:

```
POST /bookmarks { url, title?, description?, folder_id? } → Bookmark
PATCH /bookmarks/:id { title?, description?, folder_id? } → Bookmark
DELETE /bookmarks/:id → void
POST /bookmarks/:id/archive → Bookmark
GET /bookmarks/folders → List<Folder>
```

### Claude's Actions

1. **Check existing domain** - Read `domain/entities/bookmark.dart`
2. **Add missing fields** - `isArchived`, `folderId` if not present
3. **Create request models** - `CreateBookmarkRequest`, `UpdateBookmarkRequest`
4. **Update repository interface** - Add new methods
5. **Update repository impl** - Implement API calls
6. **Update mock repository** - Match interface

---

## Generated Structure Summary

After running `/data {feature}`:

```
lib/features/{feature}/
├── domain/                    # Pure Dart, no dependencies
│   ├── entities/
│   │   └── {entity}.dart     # Domain entity
│   └── repositories/
│       └── {feature}_repository.dart  # Interface
└── data/                      # Freezed + Dio
    ├── models/
    │   ├── {entity}_model.dart        # DTO with toEntity/fromEntity
    │   ├── create_{entity}_request.dart
    │   └── update_{entity}_request.dart
    ├── data_sources/
    │   └── {feature}_remote_data_source.dart
    └── repositories/
        ├── {feature}_repository_impl.dart
        └── mock_{feature}_repository.dart
```

---

## Input → Output Summary

| Input Source | What Claude Does |
|--------------|------------------|
| **Backend controller** | Extract routes, parse DTOs, map snake_case |
| **OpenAPI spec** | Parse paths + schemas, handle $refs |
| **Endpoint description** | Parse informal syntax, infer types |
| **Supabase tables** | Generate Supabase client calls |

| Output | Always Generated |
|--------|------------------|
| Domain entity | Pure Dart, computed properties |
| Repository interface | Uses entities only |
| Data model (DTO) | Freezed with toEntity/fromEntity |
| Request models | For POST/PUT/PATCH bodies |
| Repository impl | Dio with error mapping |
| Mock repository | For testing |
