# i18n Examples

Comprehensive before/after examples for every common scenario. Use these as templates when writing strings.

---

## 1. Error Messages

Errors should say: **What happened** + **What to do**

### Network Errors

```yaml
# ❌ BAD
errors:
  network: Network error
  timeout: Timeout
  offline: Offline

# ✅ GOOD
errors:
  network: No internet connection. Check your Wi-Fi and try again.
  timeout: Taking too long. Check your connection and try again.
  offline: You're offline. Connect to the internet to continue.
```

### Authentication Errors

```yaml
# ❌ BAD
errors:
  auth: Authentication failed
  credentials: Invalid credentials
  unauthorized: 401 Unauthorized
  session: Session expired

# ✅ GOOD
errors:
  wrongPassword: Wrong email or password. Try again.
  accountNotFound: No account with this email. Check spelling or sign up.
  sessionExpired: You've been signed out. Sign in again to continue.
  tooManyAttempts: Too many tries. Wait 5 minutes and try again.
```

### Permission Errors

```yaml
# ❌ BAD
errors:
  forbidden: Forbidden
  permission: Permission denied
  access: Access denied

# ✅ GOOD
errors:
  noPermission: You don't have access to this. Ask the owner to invite you.
  cameraBlocked: Camera access needed. Turn it on in Settings.
  photosBlocked: Photo access needed. Turn it on in Settings > Photos.
```

### Validation Errors

```yaml
# ❌ BAD
errors:
  invalid: Invalid input
  required: Required field
  format: Invalid format

# ✅ GOOD
errors:
  emailFormat: Enter an email like name@example.com
  passwordShort: Use at least 8 characters
  passwordWeak: Add a number or symbol to make it stronger
  nameRequired: Enter your name to continue
  phoneFormat: Enter a phone number like +1 555 123 4567
```

### Server Errors

```yaml
# ❌ BAD
errors:
  server: Server error
  internal: Internal error
  error500: Error 500

# ✅ GOOD
errors:
  serverBusy: Our servers are busy. Try again in a few minutes.
  maintenance: We're updating the app. Back soon!
  unexpected: Something went wrong on our end. Try again.
```

### Not Found Errors

```yaml
# ❌ BAD
errors:
  notFound: Not found
  missing: Resource missing
  error404: 404 Error

# ✅ GOOD
errors:
  photoNotFound: This photo was deleted or moved.
  pageNotFound: This page doesn't exist anymore.
  userNotFound: This person's account was deleted.
  linkExpired: This link expired. Ask for a new one.
```

---

## 2. Button Labels

Buttons should complete: **"I want to ___"**

### Action Buttons

```yaml
# ❌ BAD
buttons:
  ok: OK
  yes: Yes
  submit: Submit
  confirm: Confirm

# ✅ GOOD
buttons:
  saveChanges: Save changes
  createAccount: Create account
  sendMessage: Send message
  placeOrder: Place order
  startTrial: Start free trial
```

### Destructive Buttons

```yaml
# ❌ BAD
buttons:
  delete: Delete
  remove: Remove
  cancel: Cancel

# ✅ GOOD
buttons:
  deletePhoto: Delete photo
  deleteAccount: Delete my account
  removeFromList: Remove from list
  cancelSubscription: Cancel subscription
  discardChanges: Discard changes
```

### Navigation Buttons

```yaml
# ❌ BAD
buttons:
  back: Back
  next: Next
  continue: Continue

# ✅ GOOD
buttons:
  back: Back
  next: Next
  skipForNow: Skip for now
  continueToPayment: Continue to payment
  goToSettings: Go to Settings
  viewDetails: View details
```

### Toggle Buttons

```yaml
# ❌ BAD
buttons:
  enable: Enable
  disable: Disable
  on: On
  off: Off

# ✅ GOOD
buttons:
  turnOn: Turn on
  turnOff: Turn off
  enableNotifications: Turn on notifications
  disableNotifications: Turn off notifications
```

---

## 3. Confirmation Dialogs

**Never**: "Are you sure?" with [Cancel] [OK]
**Always**: State the action with clear outcome buttons

### Delete Confirmations

```yaml
# ❌ BAD - Confusing buttons
dialogs:
  delete:
    title: Are you sure?
    message: This action cannot be undone.
    confirm: OK
    cancel: Cancel

# ✅ GOOD - Clear outcomes
dialogs:
  deletePhoto:
    title: Delete this photo?
    message: It will be gone forever. You can't undo this.
    confirm: Delete photo
    cancel: Keep photo

  deleteAccount:
    title: Delete your account?
    message: All your data will be permanently deleted. This cannot be undone.
    confirm: Delete my account
    cancel: Keep my account

  deleteMessage:
    title: Delete this message?
    message: It will be removed from this conversation.
    confirm: Delete
    cancel: Keep message
```

### Discard Changes

```yaml
# ❌ BAD
dialogs:
  discard:
    title: Discard changes?
    confirm: Yes
    cancel: No

# ✅ GOOD
dialogs:
  discardChanges:
    title: You have unsaved changes
    message: Your changes will be lost if you leave now.
    confirm: Discard changes
    cancel: Keep editing

  discardDraft:
    title: Discard this draft?
    message: Your message won't be saved.
    confirm: Discard
    cancel: Keep writing
```

### Sign Out

```yaml
# ❌ BAD
dialogs:
  signOut:
    title: Sign out?
    confirm: Yes
    cancel: No

# ✅ GOOD
dialogs:
  signOut:
    title: Sign out?
    message: You'll need to sign in again to access your account.
    confirm: Sign out
    cancel: Stay signed in
```

### Cancel Subscription

```yaml
# ❌ BAD
dialogs:
  cancel:
    title: Cancel subscription?
    confirm: Cancel
    cancel: Cancel  # Confusing!

# ✅ GOOD
dialogs:
  cancelSubscription:
    title: Cancel your subscription?
    message: You'll lose access to premium features on March 15.
    confirm: Cancel subscription
    cancel: Keep subscription
```

### Send/Share

```yaml
# ✅ GOOD
dialogs:
  sendToMany:
    title: Send to 50 people?
    message: Everyone in this group will receive your message.
    confirm: Send to all
    cancel: Go back

  sharePublicly:
    title: Share publicly?
    message: Anyone with the link can see this.
    confirm: Share publicly
    cancel: Keep private
```

---

## 4. Empty States

Empty states should: **Explain what goes here** + **How to add content**

### First-Time Empty

```yaml
# ❌ BAD
empty:
  title: No items
  message: Nothing here

# ✅ GOOD
empty:
  photos:
    title: No photos yet
    message: Photos you take or upload will appear here.
    action: Add your first photo

  messages:
    title: No messages yet
    message: Start a conversation with someone.
    action: Send a message

  favorites:
    title: No favorites yet
    message: Tap the heart on items you love to save them here.
    action: Browse items
```

### Search No Results

```yaml
# ❌ BAD
empty:
  search: No results

# ✅ GOOD
empty:
  searchNoResults:
    title: No results for "{query}"
    message: Try different keywords or check your spelling.
    action: Clear search

  searchNoResultsFiltered:
    title: No matches
    message: Try removing some filters.
    action: Clear filters
```

### Error Empty State

```yaml
# ❌ BAD
empty:
  error: Failed to load

# ✅ GOOD
empty:
  loadError:
    title: Couldn't load your photos
    message: Check your connection and try again.
    action: Try again
```

---

## 5. Loading States

### Short Operations

```yaml
# ❌ BAD - Vague
loading:
  default: Loading...
  wait: Please wait...
  working: Working...

# ✅ GOOD - Specific
loading:
  photos: Loading photos...
  messages: Loading messages...
  profile: Loading profile...
```

### Long Operations

```yaml
# ✅ GOOD - Reassuring
loading:
  uploading: Uploading your photo...
  processing: Processing your order...
  creatingAccount: Creating your account...
  importingData: Importing your data... This may take a minute.
```

### Multi-Step

```yaml
# ✅ GOOD - Progress updates
loading:
  payment:
    step1: Verifying your card...
    step2: Processing payment...
    step3: Confirming order...
    complete: All done!
```

---

## 6. Success Messages

### Brief Confirmations

```yaml
# ❌ BAD - Vague
success:
  done: Done!
  success: Success!
  complete: Complete!

# ✅ GOOD - Specific
success:
  saved: Changes saved
  sent: Message sent
  copied: Copied to clipboard
  added: Added to favorites
  deleted: Photo deleted
```

### With Next Steps

```yaml
# ✅ GOOD - Guidance
success:
  accountCreated: Account created! Check your email to verify.
  passwordReset: Password updated. Sign in with your new password.
  orderPlaced: Order placed! Confirmation sent to your email.
  inviteSent: Invite sent to {email}
```

---

## 7. Form Fields

### Labels

```yaml
# ❌ BAD - Ambiguous
labels:
  name: Name
  email: Email

# ✅ GOOD - Specific
labels:
  fullName: Full name
  firstName: First name
  lastName: Last name
  displayName: Display name (shown to others)
  email: Email address
  workEmail: Work email
  phone: Phone number
```

### Placeholders (Hints)

```yaml
# ❌ BAD - Instructions
placeholders:
  email: Enter your email
  phone: Enter phone number

# ✅ GOOD - Examples
placeholders:
  email: name@example.com
  phone: +1 555 123 4567
  website: https://example.com
  date: MM/DD/YYYY
  search: Search by name or email
```

### Help Text

```yaml
# ✅ GOOD - Requirements upfront
help:
  password: At least 8 characters with a number
  username: Letters, numbers, and underscores only
  bio: Up to 150 characters. Shown on your profile.
  cardNumber: The 16 digits on the front of your card
```

---

## 8. Notifications

### Push Notifications

```yaml
# ❌ BAD - Vague
notifications:
  new: New notification
  update: Update available

# ✅ GOOD - Specific and actionable
notifications:
  newMessage:
    title: "{sender} sent you a message"
    body: "{preview}..."

  orderShipped:
    title: Your order is on the way!
    body: Arriving by {date}. Tap to track.

  paymentFailed:
    title: Payment failed
    body: Update your card to keep your subscription.

  reminder:
    title: "Reminder: {task}"
    body: Due today at {time}
```

---

## 9. Onboarding

```yaml
# ❌ BAD - Generic
onboarding:
  page1: Welcome!
  page2: Features
  page3: Get started

# ✅ GOOD - Value-focused
onboarding:
  welcome:
    title: Keep your memories safe
    description: All your photos backed up automatically.

  organize:
    title: Find any photo instantly
    description: Search by date, place, or who's in it.

  share:
    title: Share with the people you love
    description: Create albums and invite family and friends.
```

---

## 10. Settings

```yaml
# ✅ GOOD - Clear explanations
settings:
  appearance:
    title: Appearance
    theme:
      title: Theme
      system: Match device
      light: Light
      dark: Dark

  notifications:
    title: Notifications
    push:
      title: Push notifications
      description: Get notified about messages and updates

  privacy:
    title: Privacy
    analytics:
      title: Help improve the app
      description: Share anonymous usage data
```

---

## 11. Authentication (Supabase-specific)

This template uses Supabase. Handle these auth scenarios:

```yaml
auth:
  login:
    title: Welcome back
    subtitle: Sign in to continue
    emailLabel: Email
    passwordLabel: Password
    forgotPassword: Forgot password?
    signInButton: Sign in
    noAccount: New here? Create an account

  signup:
    title: Create your account
    subtitle: Join us in just a minute
    signUpButton: Create account
    hasAccount: Already have an account? Sign in
    terms: By signing up, you agree to our Terms and Privacy Policy

  errors:
    invalidCredentials: Wrong email or password. Try again.
    emailNotVerified: Check your email to verify your account.
    userExists: An account with this email already exists. Try signing in.
    weakPassword: Use a stronger password with numbers and symbols.
    tooManyRequests: Too many attempts. Try again in a few minutes.
    emailNotFound: No account with this email. Check spelling or sign up.

  otp:
    title: Check your messages
    subtitle: We sent a 6-digit code to {destination}
    resend: Didn't get it? Send again
    resendIn: Send again in {seconds}s
    wrongCode: Wrong code. Check and try again.
    codeExpired: Code expired. Request a new one.

  socialLogin:
    continueWithGoogle: Continue with Google
    continueWithApple: Continue with Apple
    failed: Couldn't sign in with {provider}. Try again.
    cancelled: Sign in cancelled.

  passwordReset:
    title: Reset your password
    subtitle: We'll send a reset link to your email
    sendLink: Send reset link
    sent: Check your email for the reset link.
    newPassword: Create a new password
    confirm: Reset password
```

---

## Quick Reference: Word Substitutions

| ❌ Avoid | ✅ Use Instead |
|---------|---------------|
| Invalid | Wrong / Not valid |
| Error occurred | Could not [action] |
| Failed | Didn't work / Could not |
| Required | Needed |
| Credentials | Email and password |
| Authenticate | Sign in |
| Terminate | End / Stop |
| Execute | Run / Do |
| Prohibited | Not allowed |
| Insufficient | Not enough |
| Mandatory | Required / Needed |
| Retry | Try again |
| Proceed | Continue |
| Abort | Cancel / Stop |
| Parameter | Setting / Option |
| Null/Empty | None / Nothing |
| Connectivity | Internet / Connection |
| Persist | Save / Keep |
| Retrieve | Get / Load |

---

## Tone Examples

### Error Tone

```yaml
# ❌ TOO ROBOTIC
error: "Error: Operation failed. Code: ERR_NET_001"

# ❌ TOO CASUAL
error: "Oops! Something broke! 🙈"

# ❌ BLAMING USER
error: "You entered an invalid email address"

# ✅ JUST RIGHT
error: "Couldn't connect. Check your internet and try again."
```

### Success Tone

```yaml
# ❌ OVER THE TOP
success: "Awesome!!! 🎉🎉🎉 You did it!"

# ❌ TOO DRY
success: "Operation completed successfully"

# ✅ JUST RIGHT
success: "Photo saved"
success: "Message sent"
success: "Changes saved"
```
