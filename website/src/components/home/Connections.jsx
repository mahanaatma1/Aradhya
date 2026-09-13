import KnowledgeGraph from '../graph/KnowledgeGraph.jsx';
import Section from '../ui/Section.jsx';
import { getStats, contentKeys } from '../../services/contentService.js';
import useAsync from '../../hooks/useAsync.js';

/**
 * "Everything is connected." — section 7.
 *
 * The graph itself is live DOM over SVG (see KnowledgeGraph); this wrapper only
 * supplies the framing and the counted line underneath it.
 */
export default function Connections() {
  const { data: stats } = useAsync(() => getStats(), [], { preloadKey: contentKeys.stats });

  return (
    <Section
      eyebrow="Knowledge graph"
      title="Everything is connected."
      lead="A person leads to the text they appear in, the text to the place it was spoken, the place to the festival kept there. Follow a thread as far as it goes."
      tone="kraft"
      align="center"
      ornament
    >
      <KnowledgeGraph />

      {stats && (
        <p className="mt-9 text-center text-[0.84rem] text-ink-faint">
          {stats.relations.toLocaleString()} stated relationships across {stats.entities} entries —
          every one of them drawn from the curated set, not inferred.
        </p>
      )}
    </Section>
  );
}
