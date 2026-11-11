# Finding the seam

- [Reading the history](#reading-the-history)
- [Claim exports, insurer by insurer](#claim-exports-insurer-by-insurer)
- [Checking the seam](#checking-the-seam)

Evidence comes before a seam. This reference reads the version history
for the places that keep changing, then follows claim exports as one
insurer after another arrives, to show the point where a seam repaid
its cost.

## Reading the history

Read the log for a requirement, not for the whole repository. A change
request is the unit: pick one and list the files it touched. Then look
for repeats.

- The same function is edited by most changes for that request.
- The same set of files changes together in the same commits.
- A change that started as one branch has grown a chain of conditions.

Ask the business which case it has promised next. A plan is evidence
only when it names a case and a reason, not when it says the system
should be flexible.

Read the history before choosing an axis. If two different requests
touch the same file for different reasons, the file may hold two
variations and needs two seams, not one.

## Claim exports, insurer by insurer

The clinic first sent claims to one insurer. `ClaimExport` wrote that
insurer's layout directly: one method, one layout name. A seam would
have added an interface with one implementation, so there was none.

The second insurer arrived with a different layout. The method grew a
condition. The two cases were visible, but the change was still small,
and the second case alone did not prove which part would keep changing.

The third insurer made the chain three deep, and the business named a
fourth for the next quarter. Now the axis was clear: the insurer's
layout is what changes, and the export routine is what stays. The seam
became worth it at the third real case, not before it.

Before:

```text
enum InsurerCode
  Northmere
  Arden
  Vale

class ClaimExport
  - claims: ClaimBook
  + new(claims: ClaimBook)
  + file(insurer: InsurerCode): ClaimFile
    if insurer = Northmere then
      return new ClaimFile(claims.all(), "northmere")
    else
      if insurer = Arden then
        return new ClaimFile(claims.all(), "arden")
      else
        return new ClaimFile(claims.all(), "vale")
```

The interface holds only what the export routine needs. Each insurer's
layout stays in its own adapter, added one format at a time.

After:

```text
interface ClaimFormat
  + export(claims: List<Claim>): ClaimFile

class NorthmereFormat implements ClaimFormat
  + export(claims: List<Claim>): ClaimFile
    return new ClaimFile(claims, "northmere")

class ArdenFormat implements ClaimFormat
  + export(claims: List<Claim>): ClaimFile
    return new ClaimFile(claims, "arden")

class ValeFormat implements ClaimFormat
  + export(claims: List<Claim>): ClaimFile
    return new ClaimFile(claims, "vale")

class ClaimExport
  - claims: ClaimBook
  - format: ClaimFormat
  + new(claims: ClaimBook, format: ClaimFormat)
  + file(): ClaimFile
    return format.export(claims.all())
```

`ClaimExport`'s fields are set by its constructor and read once in
`file`. Each adapter receives the claims and returns one file. The seam
costs one change to the callers now; after that, the fourth insurer is
a fourth adapter, and no caller changes again.

## Checking the seam

A seam is worth its cost when all three hold:

1. The next real case lands as a new class or entry, and no tested
   caller changes.
2. The interface names the variation, not one adapter's technology.
3. The history, or a case the business has named with a reason, shows
   the axis, not a single case.

When one fails, keep the direct code and wait for the next case. A
small duplication is cheaper than a seam on an axis nobody has
confirmed.
