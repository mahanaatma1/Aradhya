import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import Glyph from '../art/Glyph.jsx';
import { gradientFor } from '../../config/taxonomy.js';

/**
 * One row in the search dropdown: small glyph, title, category, short
 * description, arrow. Rendered as a real link so middle-click and "open in new
 * tab" behave, while carrying the listbox option semantics for keyboard users.
 */
export default function SearchSuggestion({ record, active = false, id, onSelect, onHover }) {
  const [from, to] = gradientFor(record.accent);

  return (
    <Link
      id={id}
      role="option"
      aria-selected={active}
      data-active={active || undefined}
      to={record.href}
      onClick={onSelect}
      // The mouse should agree with the keyboard: hovering moves the selection.
      onMouseMove={onHover}
      className={`flex items-center gap-3.5 px-3 py-2.5 transition-colors duration-150
                  ${active ? 'bg-terra/[0.07]' : 'hover:bg-paper-2/70'}`}
    >
      <span
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[0.6rem] text-white/90"
        style={{ background: `linear-gradient(135deg, ${from}, ${to})` }}
      >
        <Glyph name={record.glyph} size={17} />
      </span>

      <span className="min-w-0 flex-1">
        <span className="flex items-baseline gap-2">
          <span className="truncate text-[0.95rem] font-medium text-ink">{record.title}</span>
          {record.titleHi && (
            <span className="hidden shrink-0 font-deva text-[0.78rem] text-ink-faint sm:inline">
              {record.titleHi}
            </span>
          )}
        </span>
        <span className="mt-0.5 flex items-center gap-1.5 text-[0.78rem] text-ink-faint">
          <span className="shrink-0 font-medium text-terra/85">{record.badge}</span>
          {record.summary && (
            <>
              <span aria-hidden="true">·</span>
              <span className="truncate">{record.summary}</span>
            </>
          )}
        </span>
      </span>

      <ArrowRight
        size={15}
        strokeWidth={1.8}
        aria-hidden="true"
        className={`shrink-0 transition-all duration-200 ${
          active ? 'translate-x-0 text-terra opacity-100' : '-translate-x-1 text-ink-faint opacity-0'
        }`}
      />
    </Link>
  );
}
