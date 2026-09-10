# CSP11 Firestore Final Rules Hardening P2

## What the audit found

The live Firestore rules are currently public:

```text
match /{document=**} {
  allow read, write: if true;
}
```

The repository access audit identified only three active Cloud Firestore collections in application code:

- `users`
- `questions`
- `contentVersions`

Persistent learner progress is currently local and is not yet written to Firestore.

## Security model

### users/{uid}
- learner may create only their own profile
- self-created role must be `student`
- learner may read only own profile
- learner may update only approved profile fields
- `uid`, `email`, `role`, and `createdAt` are immutable to learner
- learner cannot list users or delete profile
- admin may manage users/roles

### questions/{questionId}
- authenticated learner may read only documents with `status == "published"`
- admin may read/write all lifecycle states

### contentVersions/{contentVersionId}
- authenticated learner may read only `copyType == "published"` AND `status == "published"`
- admin may read/write drafts and published copies

### all other paths
Denied by default.

## Required application compatibility change

`QuizService` currently asks `CloudQuestionRepository.loadAll()` and filters
published questions in memory. Firestore rules cannot safely authorize a query
that can return draft/review/validated documents merely because the client later
filters them.

P2 adds `CloudQuestionRepository.loadPublished()` with a Firestore
`where('status', isEqualTo: 'published')` query and changes only the student
`QuizService` initialization path to use it. Admin Question Bank code continues
to use `loadAll()`.

## Deployment gate

DO NOT publish the new Firebase rules until all of the following are confirmed:

1. The existing administrator has a `/users/{adminUid}` document whose `role`
   field is exactly `admin`.
2. The patch validation suite passes.
3. Web and Android smoke tests pass while using the local code changes.
4. After publication, immediately test admin Content Studio, learner published
   content, learner quizzes, learner registration, and password/verification
   flows.

No deploy, stage, commit, or push is performed by the patch.
