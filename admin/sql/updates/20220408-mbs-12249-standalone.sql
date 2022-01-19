\set ON_ERROR_STOP 1

BEGIN;

ALTER TABLE area_containment
   ADD CONSTRAINT area_containment_fk_descendant
   FOREIGN KEY (descendant)
   REFERENCES area(id);

ALTER TABLE area_containment
   ADD CONSTRAINT area_containment_fk_parent
   FOREIGN KEY (parent)
   REFERENCES area(id);

CREATE OR REPLACE TRIGGER a_ins_l_area_area AFTER INSERT ON l_area_area
    FOR EACH ROW EXECUTE PROCEDURE a_ins_l_area_area_mirror();

CREATE OR REPLACE TRIGGER a_upd_l_area_area AFTER UPDATE ON l_area_area
    FOR EACH ROW EXECUTE PROCEDURE a_upd_l_area_area_mirror();

CREATE OR REPLACE TRIGGER a_del_l_area_area AFTER DELETE ON l_area_area
    FOR EACH ROW EXECUTE PROCEDURE a_del_l_area_area_mirror();

COMMIT;
