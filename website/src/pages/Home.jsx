import HeroSearch from '../components/search/HeroSearch.jsx';
import ExploreDoors from '../components/home/ExploreDoors.jsx';
import EpicsShowcase from '../components/home/EpicsShowcase.jsx';
import ScriptureShelf from '../components/home/ScriptureShelf.jsx';
import Connections from '../components/home/Connections.jsx';
import PracticeStrip from '../components/home/PracticeStrip.jsx';
import OfflineFirst from '../components/home/OfflineFirst.jsx';
import JourneyStarters from '../components/home/JourneyStarters.jsx';
import TempleRail from '../components/home/TempleRail.jsx';
import LearnByPlay from '../components/home/LearnByPlay.jsx';
import useSeo from '../hooks/useSeo.js';
import { PAGE_META, siteJsonLd } from '../config/seo.js';
import { routes } from '../config/routes.js';

/**
 * The home page: search first, then the library it searches.
 *
 * The order is a funnel — find the thing you came for, discover the shape of
 * what else is here, then take it with you.
 */

// Built once: a fresh object each render would make useSeo rewrite the tag.
const HOME_JSON_LD = siteJsonLd();

export default function Home() {
  useSeo({ ...PAGE_META[routes.home], jsonLd: HOME_JSON_LD });

  return (
    <>
      <HeroSearch />
      <ExploreDoors />
      <EpicsShowcase />
      <ScriptureShelf />
      <Connections />
      <PracticeStrip />
      <OfflineFirst />
      <JourneyStarters />
      <TempleRail />
      <LearnByPlay />
    </>
  );
}
