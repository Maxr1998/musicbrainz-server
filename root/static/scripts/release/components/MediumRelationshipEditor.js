/*
 * @flow
 * Copyright (C) 2020 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import * as React from 'react';
import * as tree from 'weight-balanced-tree';

import {DISPLAY_NONE_STYLE} from '../../common/constants.js';
import usePagedMediumTable from '../../common/hooks/usePagedMediumTable.js';
import type {
  MediumRecordingStateT,
  MediumRecordingStateTreeT,
  RelationshipDialogLocationT,
} from '../../relationship-editor-v2/types.js';
import type {
  ReleaseRelationshipEditorActionT,
} from '../../relationship-editor-v2/types/actions.js';

import TrackRelationshipEditor from './TrackRelationshipEditor.js';

type PropsT = {
  +dialogLocation: RelationshipDialogLocationT | null,
  +dispatch: (ReleaseRelationshipEditorActionT) => void,
  +hasUnloadedTracks: boolean,
  +isExpanded: boolean,
  +medium: MediumWithRecordingsT,
  +recordingStates: MediumRecordingStateTreeT | null,
  +release: ReleaseWithMediumsT,
  +tracks: $ReadOnlyArray<TrackWithRecordingT> | null,
};

export type WritableReleasePathsT = Map<number, Set<number>>;

const getColumnCount = () => 3;

function compareRecordingWithRecordingState(
  recording: RecordingT,
  recordingState: MediumRecordingStateT,
): number {
  return recording.id - recordingState.recording.id;
}

const MediumRelationshipEditor = (React.memo<PropsT>(({
  dialogLocation,
  dispatch,
  hasUnloadedTracks,
  isExpanded,
  medium,
  recordingStates,
  release,
  tracks,
}: PropsT) => {
  const tableVars = usePagedMediumTable({
    dispatch,
    getColumnCount,
    release,
    medium,
    tracks,
    hasUnloadedTracks,
    isExpanded,
  });

  const selectMediumRecordings = React.useCallback((
    event: SyntheticEvent<HTMLInputElement>,
  ) => {
    dispatch({
      isSelected: event.currentTarget.checked,
      type: 'toggle-select-medium-recordings',
      recordingStates,
    });
  }, [dispatch, recordingStates]);

  const selectMediumWorks = React.useCallback((
    event: SyntheticEvent<HTMLInputElement>,
  ) => {
    dispatch({
      isSelected: event.currentTarget.checked,
      type: 'toggle-select-medium-works',
      recordingStates,
    });
  }, [dispatch, recordingStates]);

  return (
    <>
      <tbody>
        <tr className="subh">
          <td />
          <td>
            <input
              className="medium-recordings"
              defaultChecked={false}
              id={'medium-recordings-checkbox-' + String(medium.id)}
              onChange={selectMediumRecordings}
              type="checkbox"
            />
            {' '}
            {tableVars.mediumHeaderLink}
          </td>
          <td>
            <input
              className="medium-works"
              defaultChecked={false}
              id={'medium-works-checkbox-' + String(medium.id)}
              onChange={selectMediumWorks}
              type="checkbox"
            />
          </td>
        </tr>
      </tbody>
      <tbody style={isExpanded ? null : DISPLAY_NONE_STYLE}>
        {(tableVars.loadedTrackCount /*:: && tracks */) ? (
          tracks.map((track) => {
            const recordingState = tree.find(
              recordingStates,
              track.recording,
              compareRecordingWithRecordingState,
            );
            return recordingState ? (
              <TrackRelationshipEditor
                dialogLocation={
                  (
                    dialogLocation != null &&
                    (dialogLocation.track?.id) === track.id
                  ) ? dialogLocation : null
                }
                dispatch={dispatch}
                key={track.id}
                recordingState={recordingState}
                showArtists={tableVars.showArtists}
                track={track}
              />
            ) : null;
          })
        ) : hasUnloadedTracks ? null : (
          <tr>
            <td colSpan="3">
              {l('The tracklist for this medium is unknown.')}
            </td>
          </tr>
        )}
        {tableVars.pagingElements}
      </tbody>
    </>
  );
}): React.AbstractComponent<PropsT>);

export default MediumRelationshipEditor;
