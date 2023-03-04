// @flow

import $ from 'jquery';
import * as React from 'react';
import * as ReactDOMClient from 'react-dom/client';

import {
  LOCATION_EDITOR_FLAG,
  RELATIONSHIP_EDITOR_FLAG,
} from '../../../constants.js';
import Autocomplete2, {createInitialState as createInitialAutocompleteState}
  from '../common/components/Autocomplete2.js';
import autocompleteReducer from '../common/components/Autocomplete2/reducer.js';
import type {
  ActionT as AutocompleteActionT,
  StateT as AutocompleteStateT,
} from '../common/components/Autocomplete2/types.js';
import {keyBy} from '../common/utility/arrays.js';
import {uniqueNegativeId} from '../common/utility/numbers.js';

/*
 * typeInfo.js is generated by dump_js_type_info.pl, which is run
 * by `./script/compile_resources.sh tests`.  So it may not exist yet.
 */
// $FlowIgnore[cannot-resolve-module]
import {linkAttributeTypes} from './typeInfo.js';

type ActionT =
  | {
      +action: AutocompleteActionT<NonUrlCoreEntityT>,
      +prop: 'entityAutocomplete',
      +type: 'update-autocomplete',
    }
  | {
      +action: AutocompleteActionT<LinkAttrTypeT>,
      +prop: 'attributeTypeAutocomplete',
      +type: 'update-autocomplete',
    };

type StateT = {
  +attributeTypeAutocomplete: AutocompleteStateT<LinkAttrTypeT>,
  +entityAutocomplete: AutocompleteStateT<NonUrlCoreEntityT>,
};

const attributeTypesById = keyBy(
  (linkAttributeTypes: $ReadOnlyArray<LinkAttrTypeT>),
  x => String(x.id),
);

const attributeTypeOptions = (
  linkAttributeTypes: $ReadOnlyArray<LinkAttrTypeT>
).map((type) => {
  let level = 0;
  let parentId = type.parent_id;
  let parentType =
    parentId == null ? null : attributeTypesById.get(String(parentId));
  while (parentType) {
    level++;
    parentId = parentType.parent_id;
    parentType =
      parentId == null ? null : attributeTypesById.get(String(parentId));
  }
  return {
    entity: type,
    id: type.id,
    level,
    name: type.name,
    type: 'option',
  };
});

const disabledItemId = uniqueNegativeId();

attributeTypeOptions.push({
  disabled: true,
  entity: {
    child_order: 0,
    creditable: false,
    description: '',
    entityType: 'link_attribute_type',
    free_text: false,
    gid: '',
    id: disabledItemId,
    name: 'im disabled',
    parent_id: null,
    root_gid: '',
    root_id: disabledItemId,
  },
  id: disabledItemId,
  level: 0,
  name: 'im disabled',
  type: 'option',
});

$(function () {
  const container = document.createElement('div');
  document.body?.insertBefore(container, document.getElementById('page'));

  function reducer(state: StateT, action: ActionT) {
    switch (action.type) {
      case 'update-autocomplete':
        state = {...state};
        switch (action.prop) {
          case 'entityAutocomplete':
            state.entityAutocomplete = autocompleteReducer<NonUrlCoreEntityT>(
              state.entityAutocomplete,
              action.action,
            );
            break;
          case 'attributeTypeAutocomplete':
            state.attributeTypeAutocomplete =
              autocompleteReducer<LinkAttrTypeT>(
                state.attributeTypeAutocomplete,
                action.action,
              );
            break;
        }
        break;
    }
    return state;
  }

  const activeUser = {
    avatar: '',
    entityType: 'editor',
    has_confirmed_email_address: true,
    id: 1,
    name: 'user',
    preferences: {
      datetime_format: '',
      timezone: 'UTC',
    },
    privileges: LOCATION_EDITOR_FLAG | RELATIONSHIP_EDITOR_FLAG,
  };
  window[GLOBAL_JS_NAMESPACE] = {$c: {user: activeUser}};

  function createInitialState() {
    return {
      attributeTypeAutocomplete:
        createInitialAutocompleteState<LinkAttrTypeT>({
          entityType: 'link_attribute_type',
          id: 'attribute-type-test',
          placeholder: 'Choose an attribute type',
          staticItems: attributeTypeOptions,
          width: '200px',
        }),
      entityAutocomplete: createInitialAutocompleteState<NonUrlCoreEntityT>({
        canChangeType: () => true,
        entityType: 'artist',
        id: 'entity-test',
        width: '200px',
      }),
    };
  }

  const AutocompleteTest = () => {
    const [state, dispatch] = React.useReducer(
      reducer,
      null,
      createInitialState,
    );

    const entityAutocompleteDispatch = React.useCallback((
      action: AutocompleteActionT<NonUrlCoreEntityT>,
    ) => {
      dispatch({
        action,
        prop: 'entityAutocomplete',
        type: 'update-autocomplete',
      });
    }, []);

    const attributeTypeAutocompleteDispatch = React.useCallback((
      action: AutocompleteActionT<LinkAttrTypeT>,
    ) => {
      dispatch({
        action,
        prop: 'attributeTypeAutocomplete',
        type: 'update-autocomplete',
      });
    }, []);

    return (
      <>
        <div>
          <h2>{'Entity autocomplete'}</h2>
          <p>
            {'Current entity type:'}
            {' '}
            <select
              onChange={(event) => entityAutocompleteDispatch({
                entityType: event.target.value,
                type: 'change-entity-type',
              })}
              value={state.entityAutocomplete.entityType}
            >
              <option value="area">{'Area'}</option>
              <option value="artist">{'Artist'}</option>
              <option value="editor">{'Editor'}</option>
              <option value="event">{'Event'}</option>
              <option value="instrument">{'Instrument'}</option>
              <option value="label">{'Label'}</option>
              <option value="place">{'Place'}</option>
              <option value="recording">{'Recording'}</option>
              <option value="release">{'Release'}</option>
              <option value="release_group">{'Release Group'}</option>
              <option value="series">{'Series'}</option>
              <option value="work">{'Work'}</option>
            </select>
          </p>
          <Autocomplete2
            dispatch={entityAutocompleteDispatch}
            state={state.entityAutocomplete}
          />
        </div>
        <div>
          <h2>{'Attribute type autocomplete'}</h2>
          {/* $FlowIssue[incompatible-use] */}
          <Autocomplete2
            dispatch={attributeTypeAutocompleteDispatch}
            state={state.attributeTypeAutocomplete}
          />
        </div>
      </>
    );
  };

  const root = ReactDOMClient.createRoot(container);
  root.render(<AutocompleteTest />);
});
