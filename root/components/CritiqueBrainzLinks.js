/*
 * @flow strict
 * Copyright (C) 2018 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import EntityLink from '../static/scripts/common/components/EntityLink.js';
import {CRITIQUEBRAINZ_SERVER}
  from '../static/scripts/common/DBDefs-client.mjs';

const seeReviewsHref = (entity: ReviewableT) => {
  const reviewUrlEntity = entity.entityType === 'release_group'
    ? 'release-group'
    : entity.entityType;
  return (
    CRITIQUEBRAINZ_SERVER +
    `/${reviewUrlEntity}/` +
    entity.gid
  );
};

const writeReviewLink = (entity: ReviewableT) => (
  CRITIQUEBRAINZ_SERVER +
  `/review/write?${entity.entityType}=` +
  entity.gid
);

component CritiqueBrainzLinks(
  entity: ReviewableT,
  isSidebar: boolean = false,
) {
  const reviewCount = entity.review_count;
  const linkClassName = isSidebar ? 'wrap-anywhere' : '';

  if (reviewCount == null) {
    return l('An error occurred when loading reviews.');
  }
  if (reviewCount === 0) {
    return exp.l(
      `No one has reviewed {entity} yet.
       Be the first to {write_link|write a review}.`,
      {
        entity: <EntityLink className={linkClassName} entity={entity} />,
        write_link: writeReviewLink(entity),
      },
    );
  }
  return exp.ln(
    `There’s {reviews_link|{review_count} review} on CritiqueBrainz.
     You can also {write_link|write your own}.`,
    `There are {reviews_link|{review_count} reviews} on CritiqueBrainz.
     You can also {write_link|write your own}.`,
    reviewCount,
    {
      review_count: reviewCount,
      reviews_link: seeReviewsHref(entity),
      write_link: writeReviewLink(entity),
    },
  );
}

export default CritiqueBrainzLinks;
