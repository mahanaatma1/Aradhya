import { useState } from 'react';
import { Check, Lightbulb, Sparkles, X } from 'lucide-react';
import Reveal from '../ui/Reveal.jsx';
import Section from '../ui/Section.jsx';
import { Badge } from '../ui/Chip.jsx';
import { CardSkeleton } from '../ui/States.jsx';
import { getQuiz, getRiddles, getTrivia, allSync, contentKeys } from '../../services/contentService.js';
import useAsync from '../../hooks/useAsync.js';

/**
 * "Learn it well enough to play with it." — quiz, trivia and riddles.
 *
 * The question is a real row from the curated quiz set and it actually works, so
 * the section demonstrates the feature instead of showing a picture of it. The
 * full sets, scoring and streaks are in the app.
 */
export default function LearnByPlay() {
  const { data, loading } = useAsync(
    () => allSync([getQuiz(1), getTrivia(2), getRiddles(1)]),
    [],
    { preloadKey: contentKeys.homePlay },
  );

  const [quiz, trivia, riddles] = data ?? [];
  const question = quiz?.[0];
  const riddle = riddles?.[0];

  return (
    <Section
      eyebrow="Quiz · Trivia · Riddles"
      title="Learn it well enough to play with it."
      lead="Recall is how knowledge settles. Answer a question, read something you didn’t know, work out who is speaking from five clues."
    >
      {loading ? (
        <div className="grid gap-5 lg:grid-cols-[1.1fr_0.9fr]">
          <CardSkeleton className="h-80" />
          <CardSkeleton className="h-80" />
        </div>
      ) : (
        <div className="grid gap-5 lg:grid-cols-[1.1fr_0.9fr]">
          <Reveal>{question && <QuestionCard question={question} />}</Reveal>

          <Reveal delay={90} className="flex flex-col gap-5">
            {trivia?.length > 0 && <TriviaPanel facts={trivia} />}
            {riddle && <RiddlePanel riddle={riddle} />}
          </Reveal>
        </div>
      )}
    </Section>
  );
}

/** A working question — pick an option and it tells you. */
function QuestionCard({ question }) {
  const [picked, setPicked] = useState(null);
  const answered = picked !== null;
  const correct = picked === question.correct;

  return (
    <div className="surface stitch relative flex h-full flex-col p-6 sm:p-8">
      <div className="flex items-center gap-2.5">
        <Badge tone="terra">Quiz</Badge>
        <span className="text-[0.74rem] uppercase tracking-[0.14em] text-ink-faint">
          Level {question.difficulty}
        </span>
      </div>

      <h3 className="mt-5 font-display text-[1.3rem] leading-snug text-ink sm:text-[1.5rem]">
        {question.question}
      </h3>
      {question.questionHi && (
        <p className="mt-2 font-deva text-[0.95rem] leading-relaxed text-ink-faint">
          {question.questionHi}
        </p>
      )}

      <ul className="mt-6 space-y-2.5">
        {question.options.map((option) => {
          const isCorrect = option.key === question.correct;
          const isPicked = option.key === picked;

          let tone = 'border-ink/[0.09] bg-paper-2/40 text-ink';
          if (answered && isCorrect) tone = 'border-[#3E8E6E]/45 bg-[#3E8E6E]/[0.09] text-ink';
          else if (answered && isPicked) tone = 'border-terra/45 bg-terra/[0.07] text-ink';
          else if (answered) tone = 'border-ink/[0.07] bg-paper-2/25 text-ink-faint';

          return (
            <li key={option.key}>
              <button
                type="button"
                onClick={() => !answered && setPicked(option.key)}
                disabled={answered}
                aria-pressed={isPicked}
                className={`flex w-full items-center gap-3 rounded-md border px-4 py-3 text-left
                            text-[0.95rem] transition-all duration-300 ease-calm ${tone}
                            ${answered ? 'cursor-default' : 'hover:-translate-y-0.5 hover:border-terra/35 hover:shadow-card'}`}
              >
                <span
                  className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full
                             bg-card font-display text-[0.78rem] font-semibold text-ink-soft"
                >
                  {option.key}
                </span>
                <span className="min-w-0 flex-1">{option.text}</span>
                {answered && isCorrect && (
                  <Check size={17} strokeWidth={2.2} className="shrink-0 text-[#3E8E6E]" aria-hidden="true" />
                )}
                {answered && isPicked && !isCorrect && (
                  <X size={17} strokeWidth={2.2} className="shrink-0 text-terra" aria-hidden="true" />
                )}
              </button>
            </li>
          );
        })}
      </ul>

      <div className="mt-6 min-h-[2.75rem]" aria-live="polite">
        {answered && (
          <div className="flex items-start gap-2.5 text-[0.9rem] leading-relaxed">
            <Sparkles
              size={16}
              strokeWidth={1.8}
              aria-hidden="true"
              className={`mt-[3px] shrink-0 ${correct ? 'text-[#3E8E6E]' : 'text-terra'}`}
            />
            <p className="text-ink-soft">
              {correct ? (
                <>
                  <span className="font-medium text-ink">Right.</span> There are hundreds more in
                  the app, sorted by text and by difficulty.
                </>
              ) : (
                <>
                  <span className="font-medium text-ink">
                    {question.options.find((o) => o.key === question.correct)?.text}
                  </span>{' '}
                  is the one. Worth reading around — that is rather the point.
                </>
              )}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

function TriviaPanel({ facts }) {
  return (
    <div className="surface flex-1 p-6">
      <Badge>Trivia</Badge>
      <ul className="mt-4 space-y-4">
        {facts.map((fact) => (
          <li key={fact.fact} className="border-l-2 border-gold/50 pl-4">
            <p className="text-[0.93rem] leading-relaxed text-ink">{fact.fact}</p>
            {/* The source ships with the fact; it is shown, not paraphrased. */}
            <p className="mt-1.5 text-[0.74rem] uppercase tracking-[0.13em] text-ink-faint">
              {fact.source}
            </p>
          </li>
        ))}
      </ul>
    </div>
  );
}

/** Clues revealed one at a time, the way the app plays it. */
function RiddlePanel({ riddle }) {
  const [shown, setShown] = useState(1);
  const [revealed, setRevealed] = useState(false);
  const more = shown < riddle.clues.length;

  return (
    <div className="surface p-6">
      <Badge tone="gold">Riddle</Badge>
      <p className="mt-4 text-[0.74rem] uppercase tracking-[0.14em] text-ink-faint">
        Who am I?
      </p>

      <ol className="mt-3 space-y-2">
        {riddle.clues.slice(0, shown).map((clue, i) => (
          <li key={clue} className="flex gap-2.5 text-[0.93rem] leading-relaxed text-ink-soft">
            <span className="font-display text-[0.8rem] font-semibold text-terra">{i + 1}</span>
            <span>{clue}</span>
          </li>
        ))}
      </ol>

      <div className="mt-5 flex flex-wrap items-center gap-x-5 gap-y-2">
        {more && (
          <button
            type="button"
            onClick={() => setShown((n) => n + 1)}
            className="link-quiet inline-flex items-center gap-1.5 text-[0.86rem] font-medium"
          >
            <Lightbulb size={14} strokeWidth={1.8} aria-hidden="true" />
            Another clue
          </button>
        )}
        {!revealed ? (
          <button
            type="button"
            onClick={() => setRevealed(true)}
            className="text-[0.86rem] text-ink-faint underline decoration-ink/20 underline-offset-4
                       transition-colors hover:text-ink"
          >
            Reveal
          </button>
        ) : (
          <p className="font-display text-[1.05rem] font-semibold text-terra" aria-live="polite">
            {riddle.answer}
          </p>
        )}
      </div>
    </div>
  );
}
