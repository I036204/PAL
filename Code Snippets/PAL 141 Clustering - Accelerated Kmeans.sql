-- cleanup
DROP TYPE "T_DATA";
DROP TYPE "T_PARAMS";
DROP TYPE "T_RESULTS";
DROP TYPE "T_CENTERS";
DROP TYPE "T_CENTERSTATS";
DROP TYPE "T_STATS";
DROP TYPE "T_MODEL";
DROP TABLE "SIGNATURE";
CALL "SYS"."AFLLANG_WRAPPER_PROCEDURE_DROP"('DEVUSER', 'P_KMEANS');
DROP VIEW "V_DATA";
DROP TABLE "RESULTS";
DROP TABLE "CENTERS";
DROP TABLE "CENTERSTATS";
DROP TABLE "STATS";
DROP TABLE "MODEL";

-- procedure setup
CREATE TYPE "T_DATA" AS TABLE ("ID" INTEGER, "LIFESPEND" DOUBLE, "NEWSPEND" DOUBLE, "INCOME" DOUBLE, "LOYALTY" DOUBLE);
CREATE TYPE "T_PARAMS" AS TABLE ("NAME" VARCHAR(60), "INTARGS" INTEGER, "DOUBLEARGS" DOUBLE, "STRINGARGS" VARCHAR(100));
CREATE TYPE "T_RESULTS" AS TABLE ("ID" INTEGER, "CLUSTER_NUMBER" INTEGER, "DISTANCE" DOUBLE, "ESTIMATED" DOUBLE);
CREATE TYPE "T_CENTERS" AS TABLE ("CENTER_ID" INTEGER, "LIFESPEND" DOUBLE, "NEWSPEND" DOUBLE, "INCOME" DOUBLE, "LOYALTY" DOUBLE);
CREATE TYPE "T_CENTERSTATS" AS TABLE ("CENTER_ID" INTEGER, "VALUE" DOUBLE);
CREATE TYPE "T_STATS" AS TABLE ("NAME" VARCHAR(100), "VALUE" DOUBLE);
CREATE TYPE "T_MODEL" AS TABLE ("ID" INTEGER, "MODEL" VARCHAR(5000));

CREATE COLUMN TABLE "SIGNATURE" ("POSITION" INTEGER, "SCHEMA_NAME" NVARCHAR(256), "TYPE_NAME" NVARCHAR(256), "PARAMETER_TYPE" VARCHAR(7));
INSERT INTO "SIGNATURE" VALUES (1, 'DEVUSER', 'T_DATA', 'IN');
INSERT INTO "SIGNATURE" VALUES (2, 'DEVUSER', 'T_PARAMS', 'IN');
INSERT INTO "SIGNATURE" VALUES (3, 'DEVUSER', 'T_RESULTS', 'OUT');
INSERT INTO "SIGNATURE" VALUES (4, 'DEVUSER', 'T_CENTERS', 'OUT');
INSERT INTO "SIGNATURE" VALUES (5, 'DEVUSER', 'T_CENTERSTATS', 'OUT');
INSERT INTO "SIGNATURE" VALUES (6, 'DEVUSER', 'T_STATS', 'OUT');
INSERT INTO "SIGNATURE" VALUES (7, 'DEVUSER', 'T_MODEL', 'OUT');

CALL "SYS"."AFLLANG_WRAPPER_PROCEDURE_CREATE"('AFLPAL', 'ACCELERATEDKMEANS', 'DEVUSER', 'P_KMEANS', "SIGNATURE");

-- data & view setup
CREATE VIEW "V_DATA" AS 
	SELECT "ID", "LIFESPEND", "NEWSPEND", "INCOME", "LOYALTY"
		FROM "PAL"."CUSTOMERS"
	;
CREATE COLUMN TABLE "RESULTS" LIKE "T_RESULTS";
CREATE COLUMN TABLE "CENTERS" LIKE "T_CENTERS";
CREATE COLUMN TABLE "CENTERSTATS" LIKE "T_CENTERSTATS";
CREATE COLUMN TABLE "STATS" LIKE "T_STATS";
CREATE COLUMN TABLE "MODEL" LIKE "T_MODEL";

-- runtime
DROP TABLE "#PARAMS";
CREATE LOCAL TEMPORARY COLUMN TABLE "#PARAMS" LIKE "T_PARAMS";
--INSERT INTO "#PARAMS" VALUES ('GROUP_NUMBER', 3, null, null);
INSERT INTO "#PARAMS" VALUES ('GROUP_NUMBER_MIN', 5, null, null);
INSERT INTO "#PARAMS" VALUES ('GROUP_NUMBER_MAX', 10, null, null);
INSERT INTO "#PARAMS" VALUES ('DISTANCE_LEVEL', 2, null, null); -- 1: Manhattan, 2: Euclidean, 3: Minkowski, 4: Chebyshev (Default:2)
INSERT INTO "#PARAMS" VALUES ('MINKOWSKI_POWER', null, 3.0, null); -- only valid when DISTANCE_LEVEL=3
INSERT INTO "#PARAMS" VALUES ('MAX_ITERATION', 100, null, null);
INSERT INTO "#PARAMS" VALUES ('INIT_TYPE', 4, null, null); 1: first k, 2: random replace, 3: randon no replace, 4: patent init center (default:4)
INSERT INTO "#PARAMS" VALUES ('NORMALIZATION', 0, null, null); 0: no, 1: yes point, 2: yes column (default:0)
INSERT INTO "#PARAMS" VALUES ('THREAD_NUMBER', 4, null, null);

TRUNCATE TABLE "RESULTS";
TRUNCATE TABLE "CENTERS";
TRUNCATE TABLE "CENTERSTATS";
TRUNCATE TABLE "STATS";
TRUNCATE TABLE "MODEL";

CALL "P_KMEANS" ("V_DATA", "#PARAMS", "RESULTS", "CENTERS", "CENTERSTATS", "STATS", "MODEL") WITH OVERVIEW;

SELECT * FROM "RESULTS";
SELECT * FROM "CENTERS";
SELECT * FROM "CENTERSTATS";
SELECT * FROM "STATS";
SELECT * FROM "MODEL";
