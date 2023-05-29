--CRÉATION DES SCHÉMAS QU'ON A BESOIN
CREATE SCHEMA shop ; 
CREATE SCHEMA picture; 
CREATE SCHEMA forum; 

--CREATE SCHEMA PUBLIC; -- Il existe déjà (Dedans, il y a aura la table users, la table sera utile pour les 3 autres schémas)


---------------------------------------- U S E R --------------------------------------------------
-- Création d'un nouveau domaine pour valider le format d'un email
CREATE DOMAIN email_type AS VARCHAR
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Création d'un nouveau domaine pour la validation d'un mot de passe
CREATE DOMAIN password_type AS VARCHAR
    CHECK (LENGTH(VALUE) >= 8 AND VALUE ~ '[A-Z]');


--********** Création de la table Users
DROP TABLE IF EXISTS "users";

CREATE TABLE IF NOT EXISTS users ( ---- Création d'une table 'users' si il n'existe pas déjà
    id BIGSERIAL PRIMARY KEY NOT NULL CHECK (id > 0), -- On vérifie que l'id est supérieur à 0
    email email_type NOT NULL UNIQUE, -- unique pour éviter d'avoir plusieurs fois le même email + permettra de générer le token de récupération de mot de passe 
    password VARCHAR(128) NOT NULL, -- 128 caratères pour le hash du mot de passe SHA512(64 octest)
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),  --Lorsque l'user est créé, , le timestamp sera mis à jour
    updated_at TIMESTAMP NOT NULL DEFAULT NOW() -- Si le user modifie son mot de passe ou son email, le timestamp sera mis à jour
);


---------------------------------------- S H O P --------------------------------------------------
--********** Création de la table products

DROP TABLE IF EXISTS "products"; --Si la table "products" existe, on la supprime
CREATE TABLE IF NOT EXISTS products ( -- Création d'une table 'products' si il n'existe pas déjà
    id BIGSERIAL PRIMARY KEY NOT NULL CHECK (id > 0), -- id = Défini comme une clé primaire + on vérifie que l'id est supérieur à 0
    name VARCHAR(100) NOT NULL UNIQUE,
    price MONEY NOT NULL, 
    description TEXT,
    image VARCHAR(100),
    category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE,
    user_id BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE ON UPDATE CASCADE, -- On récupère les produits mis en vente par le user via son user id du schéma "public"
    created_at TIMESTAMP NOT NULL DEFAULT NOW(), -- Lorsque l'user ajoute un produit, , le timestamp sera mis à jour
    updated_at TIMESTAMP NOT NULL DEFAULT NOW() -- Si le user modifie un champs de son produit, le timestamp sera mis à jour
);

--********** Création de la view users_products

CREATE VIEW users_products
AS
    SELECT 
        U.id AS user_id,
        email,
        P.id AS product_id,
        P.name,
        price,
        description,
image
    FROM public.users AS U
    JOIN products AS P
        ON U.id = P.user_id;
SELECT name, price FROM users_products;

--********** Création de la view price_products
CREATE VIEW price_products
AS
    SELECT * FROM products
    ORDER BY price DESC

SELECT * FROM price_products;

--********** Création d'un trigger

CREATE OR REPLACE FUNCTION trigger_add_count_products() --Création d'un trigger
RETURNS TRIGGER AS $$
BEGIN
    UPDATE products
    SET product_count = product_count +1;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER counting_product
AFTER INSERT ON products
EXECUTE PROCEDURE trigger_add_count_products();
---------------------------------------- F O R U M --------------------------------------------------

--********** Création de la table categories
DROP TABLE IF EXISTS categories; --Si la table "categories" existe, on la supprime

CREATE TABLE IF NOT EXISTS categories( -- Création d'une table 'categories' si il n'existe pas déjà
    id BIGSERIAL PRIMARY KEY NOT NULL CHECK (id > 0), -- id = Défini comme une clé primaire + on vérifie que l'id est supérieur à 0
    user_id BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE ON UPDATE CASCADE, -- On récupère la catégorie créé par le user via son user id du schéma "public"
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(), -- Lorsque l'user ajoute une catégorie, le timestamp sera mis à jour
    updated_at TIMESTAMP NOT NULL DEFAULT NOW() -- Si le user modifie le nom d'une catégorie, le timestamp sera mis à jour
);

--********** Création de la view users_categories

CREATE VIEW users_categories
AS
    SELECT 
        U.id AS user_id,
        P.name,
        P.id AS category_id
    FROM public.users AS U
    JOIN categories AS P
        ON U.id = P.user_id;
SELECT name, category_id, user_id FROM users_categories;


--********** Création de la table messages
DROP TABLE IF EXISTS messages; --Si la table "messages" existe, on la supprime

CREATE TABLE IF NOT EXISTS messages( -- Création d'une table 'messages' si il n'existe pas déjà
    id BIGSERIAL PRIMARY KEY NOT NULL CHECK (id > 0), -- id = Défini comme une clé primaire + on vérifie que l'id est supérieur à 0
    user_id BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE ON UPDATE CASCADE, -- On récupère les messages de l'user via son user id du schéma "public"
    category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE, -- On récupère la catégorie/sujet du message via la categorie id du schéma "forum"
    content VARCHAR(255), -- Limitation de la longueur d'un message a 255 caractères 
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),  -- Lorsque l'user ajoute un message, , le timestamp sera mis à jour
    updated_at TIMESTAMP NOT NULL DEFAULT NOW() -- Si le user modifie un message du forum, le timestamp sera mis à jour
);


--********** Création de la view users_messages

CREATE VIEW users_messages
AS
    SELECT 
        U.id AS user_id,
        content,
        P.id AS message_id
    FROM public.users AS U
    JOIN messages AS P
        ON U.id = P.user_id;

SELECT content, user_id FROM users_messages;
    
---------------------------------------- P I C T U R E --------------------------------------------------
--********** Création de la table pictures


DROP TABLE IF EXISTS "pictures"; --Si la table "pictures" existe, on la supprime
CREATE TABLE IF NOT EXISTS pictures( -- Création d'une table 'pictures' si il n'existe pas déjà
    id BIGSERIAL PRIMARY KEY NOT NULL CHECK (id > 0), -- id = Défini comme une clé primaire + on vérifie que l'id est supérieur à 0
    product_id BIGINT NOT NULL REFERENCES shop.products(id) ON DELETE CASCADE ON UPDATE CASCADE, -- On récupère la photo du produit via son product id du schéma "shop"
    image VARCHAR(255),
    alt text,
    user_id BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE ON UPDATE CASCADE, 
    created_at TIMESTAMP NOT NULL DEFAULT NOW(), -- Lorsque l'user ajoute une photo, , le timestamp sera mis à jour
    updated_at TIMESTAMP NOT NULL DEFAULT NOW() -- Si le user modifie une photo de son produit, le timestamp sera mis à jour
);

--********** Création de la view products_pictures
CREATE VIEW products_pictures
AS
    SELECT 
        U.id AS user_id,
        image,
        alt,
        P.id AS picture_id
    FROM public.users AS U
    JOIN pictures AS P
        ON U.id = P.user_id;

SELECT user_id, image, alt FROM users_messages;