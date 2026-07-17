# MakeYour Privacy Policy

Effective date: July 17, 2026

MakeYour is designed as a local, private workspace for creating and using native
mini apps on iPhone. This policy explains what stays on the device, what may be
sent to a service at the user's request, and how the user controls that data.

## Data stored on the device

MakeYour stores mini-app documents, user-entered records, task state, watchlists,
cached currency rates, AI consent settings, and selected project images in the
app's local container. The user's OpenAI API key is stored separately in iOS
Keychain using When Unlocked, This Device Only protection.

MakeYour does not operate a user-account system or a synchronization server.

## OpenAI requests

AI features are optional and require the user to provide an OpenAI API key and
enable AI requests.

When generating or revising a mini app, MakeYour sends the builder instruction
and the current declarative app document directly from the device to OpenAI. When
using an AI helper inside a mini app, MakeYour first displays the exact task and
user-entered text on a confirmation screen. Only that reviewed task and text are
sent after the user taps Send.

MakeYour does not attach selected photos, local records, notification contents,
other projects, or general device data to an AI request. The API key is used only
as the authorization header for the direct OpenAI request.

OpenAI processes these requests under the agreement and data controls associated
with the user's OpenAI API account. Users should review OpenAI's privacy policy
and API data-use terms before enabling this feature.

## Exchange-rate requests

Live FX Watch sends the selected ISO base and quote currency codes to the fixed
Frankfurter API endpoint to retrieve the latest available daily reference rates.
It does not send names, email addresses, project records, photos, or the OpenAI
API key. As with any network request, the service and network operators may
process technical information such as an IP address to deliver and secure the
request.

## Data collection and tracking

The developer of MakeYour does not receive or store user projects, photos, API
keys, prompts, AI results, currency watchlists, analytics, advertising IDs, or
usage profiles on a MakeYour server. MakeYour contains no advertising SDK,
analytics SDK, data broker integration, or cross-app tracking.

Because reviewed free-form text may be transmitted to OpenAI and processed in
connection with the user's OpenAI account, MakeYour conservatively declares
Other User Content as collected for App Functionality, linked to the user, and
not used for tracking in its App Store privacy label.

Third-party processing used by MakeYour is limited to providing a feature the
user requests. These providers are expected to protect data consistently with
their published policies and applicable law and may not be used by MakeYour for
advertising or tracking.

## Retention and deletion

Local data remains until the user deletes the relevant mini app, removes the API
key, or deletes MakeYour from the device. A user can:

- remove the OpenAI API key from the AI Key screen;
- delete a mini app and its project-local images from My Apps; and
- delete MakeYour from iPhone to remove all remaining local app data.

Data processed by OpenAI is subject to the retention and deletion controls of
the user's OpenAI API account. Frankfurter may retain limited service or security
logs under its own operating practices.

## Children

MakeYour is not directed to children under 13. OpenAI features also require the
user to satisfy the minimum age and parental-permission requirements associated
with the user's OpenAI account and location.

## Security

MakeYour uses iOS sandboxing, Keychain protection, HTTPS, bounded structured
documents, and an allowlisted native capability runtime. No security method can
guarantee absolute protection, but MakeYour minimizes the data it transmits and
does not operate a central user-data store.

## Changes

This policy may be updated when MakeYour's features or providers change. The
effective date above will be updated when material changes are made.

## Contact

Privacy or support questions: `support@claude-world.com`
