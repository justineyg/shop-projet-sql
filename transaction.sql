BEGIN;

--Insertion d'une nouvelle cat
INSERT INTO categories(name, user_id) VALUES('dodo', 2);
UPDATE categories SET name = 'Bateau' WHERE id = 5;

END;
