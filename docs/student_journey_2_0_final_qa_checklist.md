# CSP11 Student Journey 2.0 Final QA Checklist

## Navigation
- [ ] Student Home opens correctly.
- [ ] Courses opens correctly.
- [ ] CSP11 Domain Journey opens correctly.
- [ ] Seven official domain names are correct.
- [ ] Domain -> Competency works.
- [ ] Competency -> Subtopic works.
- [ ] Subtopic -> StudySubtopicScreen works.
- [ ] Back navigation remains entirely inside Student navigation.

## Position
- [ ] Opening a subtopic saves learner position.
- [ ] Continue CSP11 resolves the saved position.
- [ ] Resume opens the correct subtopic.
- [ ] No Admin screen appears during resume.

## Learning Progress
- [ ] New subtopic is Not Started before opening.
- [ ] Opening records In Progress.
- [ ] Completing a subtopic records Completed.
- [ ] Completed subtopic remains completed after reopening.
- [ ] Completed subtopic does not downgrade to In Progress.

## Topic Progress
- [ ] Individual topic completion is persisted.
- [ ] Topic completion survives navigation.
- [ ] Topic completion does not falsely complete the entire subtopic.

## Navigation Within Study
- [ ] Previous works.
- [ ] Next works.
- [ ] First subtopic has no invalid Previous action.
- [ ] Last subtopic has no invalid Next action.
- [ ] Progress indicator shows the correct position.

## Progress UI
- [ ] Subtopic status is visible after completion.
- [ ] Competency progress is calculated from actual subtopics.
- [ ] Domain progress is calculated from actual subtopics.
- [ ] Progress dashboard shows real values only.
- [ ] No hard-coded learner percentages remain.

## Continue / Activity
- [ ] Continue state is correct for In Progress.
- [ ] Completed saved subtopic is treated as Review rather than falsely In Progress.
- [ ] Recent Activity only shows genuine stored activity.
- [ ] No fabricated activity appears.

## Technical
- [ ] flutter analyze returns zero issues.
- [ ] flutter test passes.
- [ ] No unnecessary duplicate service exists.
- [ ] No unnecessary duplicate screen exists.
- [ ] Existing Study theme is reused.
- [ ] Admin and Student architectures remain separate.

## Final visual review
- [ ] No overflow on desktop.
- [ ] No overflow on narrow mobile width.
- [ ] Typography remains readable.
- [ ] Domain Journey has not been accidentally redesigned.
- [ ] Progress cards match the existing premium Study visual language.
