create schema if not exists lbaw21;



DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS work CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS project_coordinator CASCADE;
DROP TABLE IF EXISTS project_member CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS task_assigned CASCADE;
DROP TABLE IF EXISTS task_comment CASCADE;
DROP TABLE IF EXISTS forum_post CASCADE;
DROP TABLE IF EXISTS project_invites CASCADE;
DROP TABLE IF EXISTS favorite CASCADE;
DROP TABLE IF EXISTS post_edition CASCADE;
DROP TABLE IF EXISTS password_resets CASCADE;
DROP TABLE IF EXISTS company_invites CASCADE;
DROP TYPE IF EXISTS task_status CASCADE;

DROP FUNCTION IF EXISTS add_favorite CASCADE;
DROP FUNCTION IF EXISTS remove_favorites CASCADE;
DROP FUNCTION IF EXISTS add_edit CASCADE;
DROP FUNCTION IF EXISTS task_search_update CASCADE;

CREATE TYPE task_status AS ENUM('Not Started','In Progress', 'Complete');

CREATE TABLE companies(
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE password_resets(
    email TEXT NOT NULL,
    token TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY(email,token)
);


CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    profile_image TEXT,
    profile_description TEXT DEFAULT NULL,
    is_admin BOOLEAN DEFAULT FALSE NOT NULL,
    company_id INTEGER REFERENCES companies(id),
    email_verified_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE work(
    users_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    PRIMARY KEY(users_id,company_id)
);

CREATE TABLE company_invites(
    id SERIAL PRIMARY KEY,
    token TEXT NOT NULL,
    email TEXT NOT NULL,
    company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    created_at TIMESTAMP
);

CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    company_id INTEGER DEFAULT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    start_date DATE,
    delivery_date DATE,
    archived BOOLEAN DEFAULT FALSE NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT date_ck CHECK (delivery_date>=start_date)
);

CREATE TABLE project_coordinator(
    users_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    PRIMARY KEY(users_id,project_id)
);

CREATE TABLE project_member(
    users_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    seenNewForumPost BOOLEAN DEFAULT TRUE NOT NULL,
    PRIMARY KEY(users_id,project_id)
);

CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    start_date DATE,
    delivery_date DATE,
    status task_status DEFAULT 'Not Started',
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT date_ck CHECK (delivery_date>start_date)
);

CREATE TABLE task_assigned(
    project_member_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    assigned_by_id INTEGER,
    assigned_on TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    notified BOOLEAN DEFAULT FALSE NOT NULL,
    new_comment BOOLEAN DEFAULT FALSE NOT NULL,
    PRIMARY KEY(project_member_id,task_id)
);

CREATE TABLE task_comment(
    id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    project_member_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    comment_date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    deleted BOOLEAN DEFAULT FALSE NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE
);


CREATE TABLE forum_post(
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(id),
    project_member_id INTEGER NOT NULL REFERENCES users(id),
    content TEXT,
    post_date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    deleted BOOLEAN DEFAULT FALSE NOT NULL
);

CREATE TABLE project_invites(
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    users_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    PRIMARY KEY(project_id,users_id)
);

CREATE TABLE favorite(
    project_id INTEGER NOT NULL REFERENCES projects(id),
    users_id INTEGER NOT NULL REFERENCES users(id),
    PRIMARY KEY(project_id,users_id)
);

CREATE TABLE post_edition(
    id SERIAL PRIMARY KEY,
    forum_post_id INTEGER NOT NULL REFERENCES forum_post(id),
    edit_date TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    content TEXT
);

-- INDEX 1

CREATE INDEX project_member_user_index  ON project_member USING btree (users_id); CLUSTER project_member USING project_member_user_index;

-- INDEX 2

CREATE INDEX project_member_project_index  ON project_member  USING hash(project_id);

-- INDEX 3

CREATE INDEX task_assigned_member_index  ON task_assigned USING btree  (project_member_id);

-- INDEX 4

ALTER TABLE tasks
ADD COLUMN tsvectors TSVECTOR;

CREATE FUNCTION task_search_update() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.tsvectors = setweight(to_tsvector('simple', NEW.name), 'A') || ' ' || setweight(to_tsvector('simple', coalesce(NEW.description, '')), 'B');
    END IF;
    IF TG_OP = 'UPDATE' THEN
        NEW.tsvectors = setweight(to_tsvector('simple', NEW.name), 'A') || ' ' || setweight(to_tsvector('simple', coalesce(NEW.description, '')), 'B');
    END IF;
    RETURN NEW;
END
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER task_search_update
BEFORE INSERT OR UPDATE ON tasks
FOR EACH ROW
EXECUTE PROCEDURE task_search_update();

-- TRIGGER 1

CREATE FUNCTION add_favorite() RETURNS TRIGGER AS
$BODY$
	BEGIN
		IF ((SELECT COUNT(*) FROM favorite WHERE NEW.users_id = users_id)=5) THEN
		RAISE EXCEPTION 'A user cant have more than 5 favorite projects';
		END IF;
		RETURN NEW;
	END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER add_favorite
BEFORE INSERT OR UPDATE ON favorite
FOR EACH ROW
EXECUTE PROCEDURE add_favorite();

-- TRIGGER 2

CREATE FUNCTION remove_favorites() RETURNS TRIGGER AS
$BODY$
BEGIN
IF (NEW.archived=TRUE) THEN
DELETE FROM favorite WHERE NEW.id = project_id;
END IF;
RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER remove_favorites
BEFORE UPDATE ON projects
FOR EACH ROW
EXECUTE PROCEDURE remove_favorites();

-- TRIGGER 3

CREATE FUNCTION add_edit() RETURNS TRIGGER AS
$BODY$
BEGIN
IF (NEW.content!=OLD.content) THEN
INSERT INTO post_edition VALUES(DEFAULT,OLD.id,DEFAULT,OLD.content);
END IF;
RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER add_edit
BEFORE UPDATE ON forum_post
FOR EACH ROW
EXECUTE PROCEDURE add_edit();

INSERT INTO users VALUES (
  DEFAULT,
  'John Doe',
  'john@example.com',
  '$2y$10$HfzIhGCCaxqyaIdGgjARSuOKAcm1Uy82YfLuNaajn6JrjLWy9Sj/W',
  '/images/avatars/profile-pic-2.png',
  DEFAULT,
  FALSE,
  NULL,
  '2021-12-28 19:10:25+00'
); -- Password is 1234. Generated using Hash::make('1234')

INSERT INTO users VALUES (
  DEFAULT,
  'Maria Doe',
  'maria@example.com',
  '$2y$10$HfzIhGCCaxqyaIdGgjARSuOKAcm1Uy82YfLuNaajn6JrjLWy9Sj/W',
  '/images/avatars/profile-pic-2.png',
  DEFAULT,
  FALSE,
  NULL,
  '2021-12-28 19:10:25+00'
); -- Password is 1234. Generated using Hash::make('1234')

INSERT INTO companies VALUES(1,'FEUP');

INSERT INTO users VALUES (
  DEFAULT,
  'Sofia Germer',
  'sofia@example.com',
  '$2y$10$HfzIhGCCaxqyaIdGgjARSuOKAcm1Uy82YfLuNaajn6JrjLWy9Sj/W',
  '/images/avatars/profile-pic-2.png',
  DEFAULT,
  TRUE,
  1,
  '2021-12-28 19:10:25+00'
); -- Password is 1234. Generated using Hash::make('1234')

INSERT INTO projects VALUES(DEFAULT,1,'LBAW','A project where we developed a website application for project management','2021-08-24', '2022-08-24', DEFAULT);
INSERT INTO projects VALUES(DEFAULT,1,'RCOM','Hello penguins, welcome to this project.','2021-08-24', '2022-08-24', DEFAULT);
INSERT INTO work VALUES(2,1); -- user id, company id
INSERT INTO work VALUES(1,1);
INSERT INTO project_member VALUES(1,1);
INSERT INTO project_member VALUES(1,2);
INSERT INTO project_coordinator VALUES(1,1);
INSERT INTO project_coordinator VALUES(1,2);
INSERT INTO forum_post VALUES (DEFAULT, 1, 1, 'A random post', '2021-12-28 19:10:25+00', DEFAULT);
INSERT INTO forum_post VALUES (DEFAULT, 1, 1, 'Another random post', '2021-12-29 19:10:25+00', DEFAULT);
INSERT INTO forum_post VALUES (DEFAULT, 2, 1, 'Something something something', '2021-12-30 19:10:25+00', DEFAULT);
INSERT INTO forum_post VALUES (DEFAULT, 2, 1, 'This is yet another post with nothing concrete', '2021-12-31 19:10:25+00', DEFAULT);
INSERT INTO projects VALUES(DEFAULT,1,'Random project','Another project with a description.','2021-08-24', '2022-08-24', DEFAULT);
INSERT INTO project_member VALUES(2,2);
INSERT INTO favorite VALUES(1,1);
INSERT INTO tasks VALUES(DEFAULT,1,'Task name','A task description you know','2021-11-19','2022-12-31','Not Started');
INSERT INTO task_comment VALUES(DEFAULT,1,1,'Hello this is a comment','2021-12-31 19:10:25+00',DEFAULT);

