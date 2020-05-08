/*
 * @flow
 * Copyright (C) 2020 Anirudh Jain
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';

import DescriptiveLink from
  '../../static/scripts/common/components/DescriptiveLink';
import Diff from '../../static/scripts/edit/components/edit/Diff';
import formatTrackLength from
  '../../static/scripts/common/utility/formatTrackLength';
import FullChangeDiff from
  '../../static/scripts/edit/components/edit/FullChangeDiff';
import yesNo from '../../static/scripts/common/utility/yesNo';
import ExpandedArtistCredit from
  '../../static/scripts/common/components/ExpandedArtistCredit';

type EditRecordingProps = {
  +display_data: {
    +artist_credit?: CompT<ArtistCreditT>,
    +comment?: CompT<string | null>,
    +length?: CompT<number | null>,
    +name?: CompT<string>,
    +recording: RecordingT,
    +video?: CompT<boolean>,
  },
};

const EditRecording = ({edit}: {+edit: EditRecordingProps}) => {
  const display = edit.display_data;
  const name = display.name;
  const comment = display.comment;
  const length = display.length;
  const video = display.video;
  const artistCredit = display.artist_credit;
  return (
    <table className="details edit-recordiing">
      <tbody>
        <tr>
          <th>{addColonText(l('Recording'))}</th>
          <td colSpan="2">
            <DescriptiveLink entity={display.recording} />
          </td>
        </tr>
        {name ? (
          <Diff
            label={addColonText(l('Name'))}
            newText={name.new}
            oldText={name.old}
            split="\s+"
          />
        ) : null}
        {comment ? (
          <Diff
            label={addColonText(l('Disambiguation'))}
            newText={comment.new ?? ''}
            oldText={comment.old ?? ''}
            split="\s+"
          />
        ) : null}
        {length ? (
          <Diff
            label={addColonText(l('Length'))}
            newText={formatTrackLength(length.new)}
            oldText={formatTrackLength(length.old)}
          />
        ) : null}
        {video ? (
          <FullChangeDiff
            label={addColonText(l('Video'))}
            newContent={yesNo(video.new)}
            oldContent={yesNo(video.old)}
          />
        ) : null}
        {artistCredit ? (
          <tr>
            <th>{addColonText(l('Artist'))}</th>
            <td className="old">
              <ExpandedArtistCredit
                artistCredit={artistCredit.old}
              />
            </td>
            <td className="new">
              <ExpandedArtistCredit
                artistCredit={artistCredit.new}
              />
            </td>
          </tr>
        ) : null}
      </tbody>
    </table>
  );
};

export default EditRecording;
