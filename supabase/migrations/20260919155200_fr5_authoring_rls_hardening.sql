-- CSP11 Phase FR5 authoring workspace RLS hardening.
-- Explicit fail-closed policies complement revoked learner privileges.

create policy authoring_content_drafts_deny_learner_direct_access
  on authoring.content_drafts
  for all
  to anon, authenticated
  using (false)
  with check (false);

create policy authoring_question_drafts_deny_learner_direct_access
  on authoring.question_drafts
  for all
  to anon, authenticated
  using (false)
  with check (false);
