-- Generated by CompileSchemaScripts.pl from:
-- 20210419-mbs-11456-fks.sql
-- 20210702-mbs-11760.sql
-- 20210916-mbs-11896.sql
-- 20210924-mbs-10327.sql
-- 20211008-mbs-11903.sql
-- 20211216-mbs-12140-12141.sql
-- 20220309-mbs-12241.sql
-- 20220314-mbs-12252-standalone.sql
-- 20220314-mbs-12253-standalone.sql
-- 20220314-mbs-12254-standalone.sql
-- 20220314-mbs-12255-standalone.sql
-- 20220322-mbs-12256-standalone.sql
\set ON_ERROR_STOP 1
BEGIN;
SET search_path = musicbrainz, public;
SET LOCAL statement_timeout = 0;
--------------------------------------------------------------------------------
SELECT '20210419-mbs-11456-fks.sql';

SET search_path = musicbrainz;


ALTER TABLE artist_credit_gid_redirect
   ADD CONSTRAINT artist_credit_gid_redirect_fk_new_id
   FOREIGN KEY (new_id)
   REFERENCES artist_credit(id);

--------------------------------------------------------------------------------
SELECT '20210702-mbs-11760.sql';


DROP TRIGGER IF EXISTS delete_unused_tag ON event_tag;
DROP TRIGGER IF EXISTS delete_unused_tag ON place_tag;
DROP TRIGGER IF EXISTS delete_unused_tag ON recording_tag;
DROP TRIGGER IF EXISTS delete_unused_tag ON release_tag;

CREATE CONSTRAINT TRIGGER delete_unused_tag
AFTER DELETE ON event_tag DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE trg_delete_unused_tag_ref();

CREATE CONSTRAINT TRIGGER delete_unused_tag
AFTER DELETE ON place_tag DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE trg_delete_unused_tag_ref();

CREATE CONSTRAINT TRIGGER delete_unused_tag
AFTER DELETE ON recording_tag DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE trg_delete_unused_tag_ref();

CREATE CONSTRAINT TRIGGER delete_unused_tag
AFTER DELETE ON release_tag DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE trg_delete_unused_tag_ref();

--------------------------------------------------------------------------------
SELECT '20210916-mbs-11896.sql';


DROP TRIGGER IF EXISTS unique_primary_for_locale ON area_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON artist_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON event_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON genre_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON instrument_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON label_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON place_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON recording_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON release_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON release_group_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON series_alias;
DROP TRIGGER IF EXISTS unique_primary_for_locale ON work_alias;

DROP FUNCTION IF EXISTS unique_primary_area_alias();
DROP FUNCTION IF EXISTS unique_primary_artist_alias();
DROP FUNCTION IF EXISTS unique_primary_event_alias();
DROP FUNCTION IF EXISTS unique_primary_genre_alias();
DROP FUNCTION IF EXISTS unique_primary_instrument_alias();
DROP FUNCTION IF EXISTS unique_primary_label_alias();
DROP FUNCTION IF EXISTS unique_primary_place_alias();
DROP FUNCTION IF EXISTS unique_primary_recording_alias();
DROP FUNCTION IF EXISTS unique_primary_release_alias();
DROP FUNCTION IF EXISTS unique_primary_release_group_alias();
DROP FUNCTION IF EXISTS unique_primary_series_alias();
DROP FUNCTION IF EXISTS unique_primary_work_alias();

--------------------------------------------------------------------------------
SELECT '20210924-mbs-10327.sql';


CREATE OR REPLACE FUNCTION del_collection_sub_on_private()
RETURNS trigger AS $$
  BEGIN
    IF NEW.public = FALSE AND OLD.public = TRUE THEN
      UPDATE editor_subscribe_collection sub
         SET available = FALSE,
             last_seen_name = OLD.name
       WHERE sub.collection = OLD.id
         AND sub.editor != NEW.editor
         AND sub.editor NOT IN (SELECT ecc.editor
                                  FROM editor_collection_collaborator ecc
                                 WHERE ecc.collection = sub.collection);
    END IF;

    RETURN NEW;
  END;
$$ LANGUAGE 'plpgsql';

--------------------------------------------------------------------------------
SELECT '20211008-mbs-11903.sql';


DROP TRIGGER IF EXISTS restore_collection_sub_on_public ON editor_collection;

CREATE OR REPLACE FUNCTION restore_collection_sub_on_public()
RETURNS trigger AS $$
  BEGIN
    IF NEW.public = TRUE AND OLD.public = FALSE THEN
      UPDATE editor_subscribe_collection sub
         SET available = TRUE,
             last_seen_name = NEW.name
       WHERE sub.collection = OLD.id
         AND sub.available = FALSE;
    END IF;

    RETURN NULL;
  END;
$$ LANGUAGE 'plpgsql';

-- Create triggers
CREATE TRIGGER restore_collection_sub_on_public AFTER UPDATE ON editor_collection
    FOR EACH ROW EXECUTE PROCEDURE restore_collection_sub_on_public();

--------------------------------------------------------------------------------
SELECT '20211216-mbs-12140-12141.sql';


-- NOTE: Make sure this script runs *before* any that recalculates
-- count/ref_count for the schema change.

DO $$
DECLARE
  empty_tag_ids INTEGER[];
  -- An "uncontrolled for whitespace" tag.
  ufw_tag RECORD;
  -- An existing "controlled for whitespace" tag ID that would conflict with
  -- ufw_tag if it were cleaned.
  existing_cfw_tag_id INTEGER;
  tag_cursor REFCURSOR;
BEGIN
  SELECT array_agg(id)
    FROM tag
   WHERE name ~ E'^\\s*$'
    INTO empty_tag_ids;

  RAISE NOTICE 'Deleting empty tag IDs: %', empty_tag_ids;

  DELETE FROM area_tag_raw WHERE tag = any(empty_tag_ids);
  DELETE FROM artist_tag_raw WHERE tag = any(empty_tag_ids);
  DELETE FROM event_tag_raw WHERE tag = any(empty_tag_ids);
  DELETE FROM instrument_tag_raw WHERE tag = any(empty_tag_ids);
  DELETE FROM label_tag_raw WHERE tag = any(empty_tag_ids);
  DELETE FROM place_tag_raw WHERE tag = any(empty_tag_ids);
  DELETE FROM recording_tag_raw WHERE tag = any(empty_tag_ids);
  DELETE FROM release_tag_raw WHERE tag = any(empty_tag_ids);
  DELETE FROM release_group_tag_raw WHERE tag = any(empty_tag_ids);
  DELETE FROM series_tag_raw WHERE tag = any(empty_tag_ids);
  DELETE FROM work_tag_raw WHERE tag = any(empty_tag_ids);

  DELETE FROM area_tag WHERE tag = any(empty_tag_ids);
  DELETE FROM artist_tag WHERE tag = any(empty_tag_ids);
  DELETE FROM event_tag WHERE tag = any(empty_tag_ids);
  DELETE FROM instrument_tag WHERE tag = any(empty_tag_ids);
  DELETE FROM label_tag WHERE tag = any(empty_tag_ids);
  DELETE FROM place_tag WHERE tag = any(empty_tag_ids);
  DELETE FROM recording_tag WHERE tag = any(empty_tag_ids);
  DELETE FROM release_tag WHERE tag = any(empty_tag_ids);
  DELETE FROM release_group_tag WHERE tag = any(empty_tag_ids);
  DELETE FROM series_tag WHERE tag = any(empty_tag_ids);
  DELETE FROM work_tag WHERE tag = any(empty_tag_ids);

  -- delete_unused_tag would normally kick in to delete these, but not if
  -- they were completely unreferenced prior to running this script.
  DELETE FROM tag WHERE id = any(empty_tag_ids);

  -- Find tags with uncontrolled whitespace and clean them up.
  --
  -- We may find that for any unclean tag, an existing tag with the
  -- "cleaned up" name already exists.  In that case, we update all
  -- *_tag_raw and *_tag rows to use the existing clean tag, and delete
  -- the unclean one.
  FOR ufw_tag IN (
    SELECT * FROM tag WHERE NOT controlled_for_whitespace(name)
  ) LOOP
    RAISE NOTICE 'Tag with uncontrolled whitespace found: id=%, name=%',
      ufw_tag.id, to_json(ufw_tag.name);

    SELECT t2.id
      FROM tag t1
      JOIN tag t2
        ON (t1.id = ufw_tag.id
            AND t2.id != ufw_tag.id
            AND t2.name = regexp_replace(btrim(t1.name), E'\\s{2,}', ' ', 'g'))
      INTO existing_cfw_tag_id;

    IF existing_cfw_tag_id IS NULL THEN
      UPDATE tag
         SET name = regexp_replace(btrim(name), E'\\s{2,}', ' ', 'g')
       WHERE id = ufw_tag.id;
    ELSE
      RAISE NOTICE 'Conflicting tag with controlled whitespace found: id=%',
        existing_cfw_tag_id;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM area_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE area_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM area_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM area_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE area_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM area_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM artist_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE artist_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM artist_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM artist_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE artist_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM artist_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM event_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE event_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM event_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM event_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE event_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM event_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM instrument_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE instrument_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM instrument_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM instrument_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE instrument_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM instrument_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM label_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE label_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM label_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM label_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE label_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM label_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM place_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE place_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM place_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM place_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE place_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM place_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM recording_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE recording_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM recording_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM recording_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE recording_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM recording_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM release_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE release_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM release_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM release_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE release_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM release_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM release_group_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE release_group_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM release_group_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM release_group_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE release_group_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM release_group_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM series_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE series_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM series_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM series_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE series_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM series_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM work_tag_raw WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE work_tag_raw SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM work_tag_raw WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      OPEN tag_cursor NO SCROLL FOR SELECT * FROM work_tag WHERE tag = ufw_tag.id FOR UPDATE;
      LOOP
        MOVE tag_cursor;
        IF FOUND THEN
          BEGIN
            UPDATE work_tag SET tag = existing_cfw_tag_id WHERE CURRENT OF tag_cursor;
          EXCEPTION WHEN unique_violation THEN
            DELETE FROM work_tag WHERE CURRENT OF tag_cursor;
          END;
        ELSE
          CLOSE tag_cursor;
          EXIT;
        END IF;
      END LOOP;

      DELETE FROM tag WHERE id = ufw_tag.id;
    END IF;
  END LOOP;
END
$$;

ALTER TABLE tag DROP CONSTRAINT IF EXISTS control_for_whitespace;
ALTER TABLE tag DROP CONSTRAINT IF EXISTS only_non_empty;

ALTER TABLE tag
  ADD CONSTRAINT control_for_whitespace CHECK (controlled_for_whitespace(name)),
  ADD CONSTRAINT only_non_empty CHECK (name != '');

--------------------------------------------------------------------------------
SELECT '20220309-mbs-12241.sql';


CREATE OR REPLACE FUNCTION controlled_for_whitespace(TEXT) RETURNS boolean AS $$
  SELECT NOT padded_by_whitespace($1);
$$ LANGUAGE SQL IMMUTABLE SET search_path = musicbrainz, public;

DROP FUNCTION IF EXISTS whitespace_collapsed(TEXT);

--------------------------------------------------------------------------------
SELECT '20220314-mbs-12252-standalone.sql';


ALTER TABLE edit_genre
   ADD CONSTRAINT edit_genre_fk_edit
   FOREIGN KEY (edit)
   REFERENCES edit(id);

ALTER TABLE edit_genre
   ADD CONSTRAINT edit_genre_fk_genre
   FOREIGN KEY (genre)
   REFERENCES genre(id)
   ON DELETE CASCADE;

--------------------------------------------------------------------------------
SELECT '20220314-mbs-12253-standalone.sql';


ALTER TABLE l_area_genre ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_area_genre ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_artist_genre ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_artist_genre ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_event_genre ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_event_genre ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_genre_genre ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_genre_genre ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));
ALTER TABLE l_genre_genre ADD CONSTRAINT non_loop_relationship CHECK (entity0 != entity1);

ALTER TABLE l_genre_instrument ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_genre_instrument ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_genre_label ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_genre_label ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_genre_place ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_genre_place ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_genre_recording ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_genre_recording ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_genre_release ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_genre_release ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_genre_release_group ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_genre_release_group ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_genre_series ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_genre_series ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_genre_url ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_genre_url ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));

ALTER TABLE l_genre_work ADD CONSTRAINT control_for_whitespace_entity0_credit CHECK (controlled_for_whitespace(entity0_credit));
ALTER TABLE l_genre_work ADD CONSTRAINT control_for_whitespace_entity1_credit CHECK (controlled_for_whitespace(entity1_credit));


ALTER TABLE l_area_genre
   ADD CONSTRAINT l_area_genre_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_area_genre
   ADD CONSTRAINT l_area_genre_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES area(id);

ALTER TABLE l_area_genre
   ADD CONSTRAINT l_area_genre_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES genre(id);

ALTER TABLE l_artist_genre
   ADD CONSTRAINT l_artist_genre_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_artist_genre
   ADD CONSTRAINT l_artist_genre_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES artist(id);

ALTER TABLE l_artist_genre
   ADD CONSTRAINT l_artist_genre_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES genre(id);

ALTER TABLE l_event_genre
   ADD CONSTRAINT l_event_genre_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_event_genre
   ADD CONSTRAINT l_event_genre_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES event(id);

ALTER TABLE l_event_genre
   ADD CONSTRAINT l_event_genre_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES genre(id);

ALTER TABLE l_genre_genre
   ADD CONSTRAINT l_genre_genre_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_genre_genre
   ADD CONSTRAINT l_genre_genre_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES genre(id);

ALTER TABLE l_genre_genre
   ADD CONSTRAINT l_genre_genre_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES genre(id);

ALTER TABLE l_genre_instrument
   ADD CONSTRAINT l_genre_instrument_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_genre_instrument
   ADD CONSTRAINT l_genre_instrument_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES genre(id);

ALTER TABLE l_genre_instrument
   ADD CONSTRAINT l_genre_instrument_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES instrument(id);

ALTER TABLE l_genre_label
   ADD CONSTRAINT l_genre_label_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_genre_label
   ADD CONSTRAINT l_genre_label_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES genre(id);

ALTER TABLE l_genre_label
   ADD CONSTRAINT l_genre_label_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES label(id);

ALTER TABLE l_genre_place
   ADD CONSTRAINT l_genre_place_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_genre_place
   ADD CONSTRAINT l_genre_place_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES genre(id);

ALTER TABLE l_genre_place
   ADD CONSTRAINT l_genre_place_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES place(id);

ALTER TABLE l_genre_recording
   ADD CONSTRAINT l_genre_recording_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_genre_recording
   ADD CONSTRAINT l_genre_recording_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES genre(id);

ALTER TABLE l_genre_recording
   ADD CONSTRAINT l_genre_recording_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES recording(id);

ALTER TABLE l_genre_release
   ADD CONSTRAINT l_genre_release_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_genre_release
   ADD CONSTRAINT l_genre_release_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES genre(id);

ALTER TABLE l_genre_release
   ADD CONSTRAINT l_genre_release_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES release(id);

ALTER TABLE l_genre_release_group
   ADD CONSTRAINT l_genre_release_group_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_genre_release_group
   ADD CONSTRAINT l_genre_release_group_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES genre(id);

ALTER TABLE l_genre_release_group
   ADD CONSTRAINT l_genre_release_group_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES release_group(id);

ALTER TABLE l_genre_series
   ADD CONSTRAINT l_genre_series_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_genre_series
   ADD CONSTRAINT l_genre_series_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES genre(id);

ALTER TABLE l_genre_series
   ADD CONSTRAINT l_genre_series_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES series(id);

ALTER TABLE l_genre_url
   ADD CONSTRAINT l_genre_url_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_genre_url
   ADD CONSTRAINT l_genre_url_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES genre(id);

ALTER TABLE l_genre_url
   ADD CONSTRAINT l_genre_url_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES url(id);

ALTER TABLE l_genre_work
   ADD CONSTRAINT l_genre_work_fk_link
   FOREIGN KEY (link)
   REFERENCES link(id);

ALTER TABLE l_genre_work
   ADD CONSTRAINT l_genre_work_fk_entity0
   FOREIGN KEY (entity0)
   REFERENCES genre(id);

ALTER TABLE l_genre_work
   ADD CONSTRAINT l_genre_work_fk_entity1
   FOREIGN KEY (entity1)
   REFERENCES work(id);


CREATE TRIGGER b_upd_l_area_genre BEFORE UPDATE ON l_area_genre
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_artist_genre BEFORE UPDATE ON l_artist_genre
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_event_genre BEFORE UPDATE ON l_event_genre
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_genre_genre BEFORE UPDATE ON l_genre_genre
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_genre_instrument BEFORE UPDATE ON l_genre_instrument
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_genre_label BEFORE UPDATE ON l_genre_label
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_genre_place BEFORE UPDATE ON l_genre_place
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_genre_recording BEFORE UPDATE ON l_genre_recording
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_genre_release BEFORE UPDATE ON l_genre_release
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_genre_release_group BEFORE UPDATE ON l_genre_release_group
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_genre_url BEFORE UPDATE ON l_genre_url
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER b_upd_l_genre_work BEFORE UPDATE ON l_genre_work
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_area_genre DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_artist_genre DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_event_genre DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_genre_genre DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_genre_instrument DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_genre_label DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_genre_place DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_genre_recording DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_genre_release DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_genre_release_group DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_genre_url DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER remove_unused_links
    AFTER DELETE OR UPDATE ON l_genre_work DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE remove_unused_links();

CREATE CONSTRAINT TRIGGER url_gc_a_upd_l_genre_url
AFTER UPDATE ON l_genre_url DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE remove_unused_url();

CREATE CONSTRAINT TRIGGER url_gc_a_del_l_genre_url
AFTER DELETE ON l_genre_url DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE remove_unused_url();


ALTER TABLE documentation.l_area_genre_example
   ADD CONSTRAINT l_area_genre_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_area_genre(id);

ALTER TABLE documentation.l_artist_genre_example
   ADD CONSTRAINT l_artist_genre_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_artist_genre(id);

ALTER TABLE documentation.l_event_genre_example
   ADD CONSTRAINT l_event_genre_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_event_genre(id);

ALTER TABLE documentation.l_genre_genre_example
   ADD CONSTRAINT l_genre_genre_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_genre_genre(id);

ALTER TABLE documentation.l_genre_instrument_example
   ADD CONSTRAINT l_genre_instrument_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_genre_instrument(id);

ALTER TABLE documentation.l_genre_label_example
   ADD CONSTRAINT l_genre_label_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_genre_label(id);

ALTER TABLE documentation.l_genre_place_example
   ADD CONSTRAINT l_genre_place_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_genre_place(id);

ALTER TABLE documentation.l_genre_recording_example
   ADD CONSTRAINT l_genre_recording_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_genre_recording(id);

ALTER TABLE documentation.l_genre_release_example
   ADD CONSTRAINT l_genre_release_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_genre_release(id);

ALTER TABLE documentation.l_genre_release_group_example
   ADD CONSTRAINT l_genre_release_group_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_genre_release_group(id);

ALTER TABLE documentation.l_genre_series_example
   ADD CONSTRAINT l_genre_series_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_genre_series(id);

ALTER TABLE documentation.l_genre_url_example
   ADD CONSTRAINT l_genre_url_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_genre_url(id);

ALTER TABLE documentation.l_genre_work_example
   ADD CONSTRAINT l_genre_work_example_fk_id
   FOREIGN KEY (id)
   REFERENCES musicbrainz.l_genre_work(id);

--------------------------------------------------------------------------------
SELECT '20220314-mbs-12254-standalone.sql';


ALTER TABLE genre_annotation
   ADD CONSTRAINT genre_annotation_fk_genre
   FOREIGN KEY (genre)
   REFERENCES genre(id);

ALTER TABLE genre_annotation
   ADD CONSTRAINT genre_annotation_fk_annotation
   FOREIGN KEY (annotation)
   REFERENCES annotation(id);

--------------------------------------------------------------------------------
SELECT '20220314-mbs-12255-standalone.sql';


ALTER TABLE genre_alias
   ADD CONSTRAINT genre_alias_fk_type
   FOREIGN KEY (type)
   REFERENCES genre_alias_type(id);

ALTER TABLE genre_alias
   ADD CONSTRAINT genre_alias_fk_genre
   FOREIGN KEY (genre)
   REFERENCES genre(id);

ALTER TABLE genre_alias_type
   ADD CONSTRAINT genre_alias_type_fk_parent
   FOREIGN KEY (parent)
   REFERENCES genre_alias_type(id);

CREATE TRIGGER end_date_implies_ended BEFORE UPDATE OR INSERT ON genre_alias
    FOR EACH ROW EXECUTE PROCEDURE end_date_implies_ended();
    
CREATE TRIGGER b_upd_genre_alias BEFORE UPDATE ON genre_alias
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();

CREATE TRIGGER search_hint BEFORE UPDATE OR INSERT ON genre_alias
    FOR EACH ROW EXECUTE PROCEDURE simplify_search_hints(2);

--------------------------------------------------------------------------------
SELECT '20220322-mbs-12256-standalone.sql';


CREATE TRIGGER update_aggregate_rating_for_insert AFTER INSERT ON artist_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_insert('artist');

CREATE TRIGGER update_aggregate_rating_for_update AFTER UPDATE ON artist_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_update('artist');

CREATE TRIGGER update_aggregate_rating_for_delete AFTER DELETE ON artist_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_delete('artist');

CREATE TRIGGER update_aggregate_rating_for_insert AFTER INSERT ON event_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_insert('event');

CREATE TRIGGER update_aggregate_rating_for_update AFTER UPDATE ON event_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_update('event');

CREATE TRIGGER update_aggregate_rating_for_delete AFTER DELETE ON event_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_delete('event');

CREATE TRIGGER update_aggregate_rating_for_insert AFTER INSERT ON label_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_insert('label');

CREATE TRIGGER update_aggregate_rating_for_update AFTER UPDATE ON label_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_update('label');

CREATE TRIGGER update_aggregate_rating_for_delete AFTER DELETE ON label_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_delete('label');

CREATE TRIGGER update_aggregate_rating_for_insert AFTER INSERT ON place_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_insert('place');

CREATE TRIGGER update_aggregate_rating_for_update AFTER UPDATE ON place_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_update('place');

CREATE TRIGGER update_aggregate_rating_for_delete AFTER DELETE ON place_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_delete('place');

CREATE TRIGGER update_aggregate_rating_for_insert AFTER INSERT ON recording_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_insert('recording');

CREATE TRIGGER update_aggregate_rating_for_update AFTER UPDATE ON recording_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_update('recording');

CREATE TRIGGER update_aggregate_rating_for_delete AFTER DELETE ON recording_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_delete('recording');

CREATE TRIGGER update_aggregate_rating_for_insert AFTER INSERT ON release_group_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_insert('release_group');

CREATE TRIGGER update_aggregate_rating_for_update AFTER UPDATE ON release_group_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_update('release_group');

CREATE TRIGGER update_aggregate_rating_for_delete AFTER DELETE ON release_group_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_delete('release_group');

CREATE TRIGGER update_aggregate_rating_for_insert AFTER INSERT ON work_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_insert('work');

CREATE TRIGGER update_aggregate_rating_for_update AFTER UPDATE ON work_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_update('work');

CREATE TRIGGER update_aggregate_rating_for_delete AFTER DELETE ON work_rating_raw
    FOR EACH ROW EXECUTE PROCEDURE update_aggregate_rating_for_raw_delete('work');

COMMIT;
