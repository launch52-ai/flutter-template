# UX Writing Guide

Guidelines for writing clear, user-friendly text that anyone can understand.

**Principle:** Write as if your reader is a 10-year-old or someone who learned English as a second language. Every word should be crystal clear with no room for misunderstanding.

---

## Core Principles

### 1. Be Specific, Not Vague

| Bad | Good | Why |
|-----|------|-----|
| "Error occurred" | "Could not save. Check your internet connection." | Tells what happened AND what to do |
| "Invalid input" | "Email must include @ symbol" | Shows exactly what's wrong |
| "Operation failed" | "Could not delete photo. Try again." | Names the action and suggests next step |
| "Something went wrong" | "Could not load your messages. Pull down to try again." | Specific problem + clear solution |

### 2. Use Plain Words

| Avoid | Use Instead |
|-------|-------------|
| "Authenticate" | "Sign in" |
| "Terminate" | "End" or "Stop" |
| "Initialize" | "Set up" or "Start" |
| "Configure" | "Set up" |
| "Utilize" | "Use" |
| "Subsequently" | "Then" or "Next" |
| "Commence" | "Start" or "Begin" |
| "Sufficient" | "Enough" |
| "Mandatory" | "Required" |
| "Retrieve" | "Get" |

### 3. Name the Action, Not the Process

| Bad | Good |
|-----|------|
| "Processing..." | "Saving your photo..." |
| "Loading..." | "Loading your messages..." |
| "Please wait..." | "Creating your account..." |
| "Working..." | "Sending email..." |

---

## Button Labels

### The Golden Rule

**Button text should complete the sentence: "I want to ___"**

| Bad | Good | Why |
|-----|------|-----|
| "OK" | "Save changes" | User knows what will happen |
| "Yes" | "Delete photo" | Clear consequence |
| "Submit" | "Create account" | Names the outcome |
| "Confirm" | "Place order" | Action is obvious |

### Avoid Confusing Button Pairs

**Never use these combinations:**

```
❌ WRONG: "Do you want to cancel?"
   [Cancel] [OK]

   Problem: Which button cancels? Both could mean "cancel"
```

```
✅ RIGHT: "Discard your changes?"
   [Keep editing] [Discard]

   Each button clearly states what happens
```

**More examples:**

| Bad Dialog | Good Dialog |
|------------|-------------|
| "Are you sure?" [Yes] [No] | "Delete this photo?" [Keep photo] [Delete] |
| "Continue?" [OK] [Cancel] | "Sign out of your account?" [Stay signed in] [Sign out] |
| "Confirm action?" [Confirm] [Cancel] | "Send message to 5 people?" [Don't send] [Send message] |

### Button Label Patterns

**Positive actions (do something):**
```yaml
# Pattern: [Verb] + [Object]
buttons:
  saveChanges: Save changes
  createAccount: Create account
  sendMessage: Send message
  addPhoto: Add photo
  startTrial: Start free trial
```

**Negative actions (stop/remove):**
```yaml
# Pattern: [Verb] + [Object] - be explicit about consequence
buttons:
  deletePhoto: Delete photo
  removeFromList: Remove from list
  cancelSubscription: Cancel subscription
  signOut: Sign out
```

**Navigation:**
```yaml
# Keep simple and directional
buttons:
  next: Next
  back: Back
  done: Done
  skip: Skip for now
  goToSettings: Go to Settings
```

---

## Error Messages

### The Formula

**Error = What happened + Why (if helpful) + What to do next**

```yaml
# BAD: Only says what happened
error: "Network error"

# BETTER: Adds what to do
error: "Network error. Please try again."

# BEST: Complete formula
error: "Could not save. Check your internet and try again."
```

### Error Message Templates

**Connection problems:**
```yaml
errors:
  noInternet: "No internet connection. Connect to Wi-Fi or mobile data to continue."
  timeout: "Taking too long. Check your connection and try again."
  serverDown: "Our servers are busy. Please try again in a few minutes."
```

**User input problems:**
```yaml
errors:
  emailFormat: "Enter an email like name@example.com"
  passwordShort: "Password needs at least 8 characters"
  fieldEmpty: "Fill in your [field name] to continue"
  invalidPhone: "Enter a phone number like +1 555 123 4567"
```

**Permission problems:**
```yaml
errors:
  notAllowed: "You don't have permission to do this. Ask the account owner for access."
  sessionExpired: "You've been signed out. Sign in again to continue."
  accountLocked: "Account locked for security. Reset your password to unlock."
```

**Not found:**
```yaml
errors:
  pageNotFound: "This page doesn't exist. It may have been moved or deleted."
  userNotFound: "No account with this email. Check the spelling or create a new account."
  itemNotFound: "This item is no longer available."
```

### What NOT to Show Users

| Never Show | Show Instead |
|------------|--------------|
| Error codes: "Error 500" | "Something went wrong on our end. Try again." |
| Technical details: "JSON parse error" | "Could not load data. Try again." |
| Stack traces | "Unexpected error. We've been notified." |
| Database errors: "Foreign key constraint" | "Could not save. Some required information is missing." |
| API responses: "401 Unauthorized" | "Session expired. Please sign in again." |

---

## Confirmation Dialogs

### Structure

```
[Title: Action being confirmed]

[Body: Consequence of the action - what will happen]

[Secondary button: Keeps things as they are]  [Primary button: Does the action]
```

### Examples

**Deleting something:**
```
Delete "Beach sunset.jpg"?

This photo will be permanently deleted. You cannot undo this.

[Keep photo]  [Delete forever]
```

**Signing out:**
```
Sign out?

You'll need to sign in again to access your account.

[Stay signed in]  [Sign out]
```

**Discarding changes:**
```
You have unsaved changes

Your changes will be lost if you leave now.

[Keep editing]  [Discard changes]
```

**Canceling subscription:**
```
Cancel your subscription?

You'll lose access to premium features on March 15, 2025.
You can restart anytime.

[Keep subscription]  [Cancel subscription]
```

### Bad vs Good Confirmations

| Bad | Good |
|-----|------|
| "Are you sure?" [Yes] [No] | "Delete this message?" [Keep] [Delete] |
| "Confirm?" [OK] [Cancel] | "Send to 50 people?" [Don't send] [Send] |
| "Continue?" [Continue] [Go back] | "Leave without saving?" [Keep editing] [Leave] |

---

## Empty States

**Empty states should:**
1. Explain what goes here
2. Tell users how to add content
3. Feel encouraging, not sad

### Templates

**First-time empty:**
```yaml
empty:
  title: "No photos yet"
  description: "Photos you take or upload will appear here."
  action: "Add your first photo"
```

**Search with no results:**
```yaml
empty:
  title: "No results for '{query}'"
  description: "Try different keywords or check your spelling."
  action: "Clear search"
```

**Filtered with no results:**
```yaml
empty:
  title: "No completed tasks"
  description: "Tasks you finish will move here."
  action: "View all tasks"
```

**Error state:**
```yaml
empty:
  title: "Could not load messages"
  description: "Check your internet connection."
  action: "Try again"
```

---

## Loading States

### Short Operations (< 3 seconds)

Keep it simple:
```yaml
loading:
  default: "Loading..."
  saving: "Saving..."
  sending: "Sending..."
```

### Longer Operations (> 3 seconds)

Be more specific and reassuring:
```yaml
loading:
  uploadingPhoto: "Uploading photo..."
  creatingAccount: "Creating your account..."
  processingPayment: "Processing payment... Don't close this page."
  syncingData: "Syncing your data... This may take a moment."
```

### Progress Updates

For multi-step processes:
```yaml
loading:
  step1: "Checking your information..."
  step2: "Setting up your account..."
  step3: "Almost done..."
  complete: "All set!"
```

---

## Form Labels and Help Text

### Labels

**Be specific about what's needed:**
```yaml
labels:
  # Bad - vague
  name: "Name"

  # Good - specific
  fullName: "Full name"
  firstName: "First name"
  lastName: "Last name"
  displayName: "Display name (shown to others)"
```

### Placeholder Text (Hint Text)

**Show format, not instructions:**
```yaml
placeholders:
  # Bad - instruction
  email: "Enter your email"

  # Good - example format
  email: "name@example.com"
  phone: "+1 555 123 4567"
  date: "MM/DD/YYYY"
  website: "https://example.com"
```

### Help Text

**Explain requirements before user makes mistakes:**
```yaml
help:
  password: "At least 8 characters with a number"
  username: "Letters, numbers, and underscores only"
  bio: "Max 150 characters. Shown on your profile."
```

---

## Success Messages

### Be Specific About What Happened

```yaml
# Bad - vague
success: "Success!"

# Good - specific
success:
  saved: "Changes saved"
  sent: "Message sent"
  deleted: "Photo deleted"
  copied: "Copied to clipboard"
  added: "Added to favorites"
```

### Include Next Steps When Helpful

```yaml
success:
  accountCreated: "Account created! Check your email to verify."
  passwordReset: "Password updated. You can now sign in."
  orderPlaced: "Order placed! You'll receive confirmation at {email}."
  inviteSent: "Invite sent to {email}. They'll get an email shortly."
```

---

## Notifications

### Title + Body Pattern

```yaml
notifications:
  newMessage:
    title: "New message from {sender}"
    body: "{preview}..."

  orderShipped:
    title: "Your order is on the way"
    body: "Arriving by {date}. Tap to track."

  paymentFailed:
    title: "Payment failed"
    body: "Update your card to continue your subscription."

  reminderDue:
    title: "Reminder: {task}"
    body: "Due today at {time}"
```

---

## Accessibility Considerations

### Screen Reader Labels

```yaml
accessibility:
  # For icon-only buttons
  closeButton: "Close"
  menuButton: "Open menu"
  searchButton: "Search"
  backButton: "Go back"

  # For images
  profilePhoto: "Profile photo of {name}"
  uploadedImage: "Image uploaded by {name}"

  # For status indicators
  unreadBadge: "{count} unread messages"
  loadingSpinner: "Loading content"
```

### Announce Changes

```yaml
accessibility:
  # After actions complete
  itemDeleted: "Item deleted"
  itemSaved: "Saved"
  copiedToClipboard: "Copied"
  errorOccurred: "Error: {message}"
```

---

## Pluralization

### Always Handle Zero, One, Many

```yaml
items:
  count(n):
    zero: "No messages"
    one: "1 message"
    other: "$n messages"

photos:
  selected(n):
    zero: "No photos selected"
    one: "1 photo selected"
    other: "$n photos selected"

time:
  minutesAgo(n):
    one: "1 minute ago"
    other: "$n minutes ago"
```

---

## Tone Guidelines

### Do

- Sound helpful and friendly
- Use "you" and "your" (speak to the user)
- Be encouraging when things go wrong
- Celebrate successes briefly

### Don't

- Sound robotic or corporate
- Blame the user for errors
- Use exclamation marks excessively!!!
- Be overly casual or use slang
- Use humor in error messages

### Examples

| Bad | Good |
|-----|------|
| "User must enter valid email" | "Enter a valid email to continue" |
| "Error: Invalid credentials entered" | "Wrong email or password. Try again." |
| "Your request has been processed successfully" | "Done!" or "Saved" |
| "Oops! Something broke! 🙈" | "Something went wrong. Try again." |

---

## Checklist for Every String

Before adding any string, verify:

- [ ] **Clear:** Would a 10-year-old understand this?
- [ ] **Actionable:** If it's an error, does it say what to do?
- [ ] **Specific:** Does it name the exact thing (photo, message, account)?
- [ ] **No jargon:** Are all words common and simple?
- [ ] **Button match:** Do button labels clearly show what happens?
- [ ] **Consistent:** Does it match the tone of other strings?
- [ ] **Length:** Will it fit in the UI (especially buttons)?

---

## Quick Reference

### Common Patterns

```yaml
# Asking to do something
"[Action] [object]?"
→ "Delete this photo?"
→ "Send message to {name}?"

# Confirming something happened
"[Object] [past tense verb]"
→ "Photo deleted"
→ "Message sent"

# Error with solution
"Could not [action]. [Solution]."
→ "Could not save. Check your connection and try again."

# Loading with context
"[Action-ing] [object]..."
→ "Saving your photo..."
→ "Loading messages..."

# Empty state
"No [objects] yet. [How to add them]."
→ "No photos yet. Tap + to add one."
```

### Words to Avoid → Use Instead

| Avoid | Use |
|-------|-----|
| Invalid | Not valid / Wrong format |
| Error | Problem / Could not |
| Failed | Did not work / Could not |
| Required | Needed / Fill in |
| Prohibited | Not allowed |
| Terminate | End / Stop |
| Execute | Run / Do |
| Parameter | Setting / Option |
| Null/Empty | None / Nothing |
| Retry | Try again |

---

## Summary

1. **Write for clarity** - A child should understand
2. **Be specific** - Name the thing, explain the problem, suggest a fix
3. **Make buttons obvious** - "I want to [button text]"
4. **Avoid confusion** - No "Cancel" button on a cancel dialog
5. **Test with real people** - If they hesitate, rewrite it
