-- cleanup
DROP TYPE "T_DATA";
DROP TYPE "T_PARAMS";
DROP TYPE "T_MAP";
DROP TYPE "T_RESULTS";
DROP TABLE "SIGNATURE";
CALL "SYS"."AFLLANG_WRAPPER_PROCEDURE_DROP"('DEVUSER', 'P_SOM');
DROP VIEW "V_DATA";
DROP TABLE "MAP";
DROP TABLE "RESULTS";
DROP VIEW "V_RESULTS";

-- procedure setup
CREATE TYPE "T_DATA" AS TABLE ("ID" INTEGER, "LIFESPEND" DOUBLE, "NEWSPEND" DOUBLE, "INCOME" DOUBLE, "LOYALTY" DOUBLE);
CREATE TYPE "T_PARAMS" AS TABLE ("NAME" VARCHAR(60), "INTARGS" INTEGER, "DOUBLEARGS" DOUBLE, "STRINGARGS" VARCHAR(100));
CREATE TYPE "T_MAP" AS TABLE ("MAP_ID" INTEGER, "LIFESPEND_WEIGHT" DOUBLE, "NEWSPEND_WEIGHT" DOUBLE, "INCOME_WEIGHT" DOUBLE, "LOYALTY_WEIGHT" DOUBLE, "ROWCOUNT" INTEGER);
CREATE TYPE "T_RESULTS" AS TABLE ("ID" INTEGER, "MAP_ID" INTEGER);

CREATE COLUMN TABLE "SIGNATURE" ("POSITION" INTEGER, "SCHEMA_NAME" NVARCHAR(256), "TYPE_NAME" NVARCHAR(256), "PARAMETER_TYPE" VARCHAR(7));
INSERT INTO "SIGNATURE" VALUES (1, 'DEVUSER', 'T_DATA', 'IN');
INSERT INTO "SIGNATURE" VALUES (2, 'DEVUSER', 'T_PARAMS', 'IN');
INSERT INTO "SIGNATURE" VALUES (3, 'DEVUSER', 'T_MAP', 'OUT');
INSERT INTO "SIGNATURE" VALUES (4, 'DEVUSER', 'T_RESULTS', 'OUT');

CALL "SYS"."AFLLANG_WRAPPER_PROCEDURE_CREATE"('AFLPAL', 'SELFORGMAP', 'DEVUSER', 'P_SOM', "SIGNATURE");

-- data & view setup
CREATE VIEW "V_DATA" AS 
	SELECT "ID", "LIFESPEND", "NEWSPEND", "INCOME", "LOYALTY"
		FROM "PAL"."CUSTOMERS"
	;
CREATE COLUMN TABLE "MAP" LIKE "T_MAP";
CREATE COLUMN TABLE "RESULTS" LIKE "T_RESULTS";
CREATE VIEW "V_RESULTS" AS
	SELECT a."ID", b."CUSTOMER", b."LIFESPEND", b."NEWSPEND", b."INCOME", b."LOYALTY", a."MAP_ID" + 1 AS CLUSTER_NUMBER 
		FROM "RESULTS" a, "PAL"."CUSTOMERS" b 
		WHERE a."ID" = b."ID"
	;

-- runtime
DROP TABLE "#PARAMS";
CREATE LOCAL TEMPORARY COLUMN TABLE "#PARAMS" LIKE "T_PARAMS";
INSERT INTO "#PARAMS" VALUES ('KERNEL_FUNCTION', 1, null, null); -- 1: gaussian, 2: bubble/flat
INSERT INTO "#PARAMS" VALUES ('NORMALIZATION', 0, null, null); -- 0: none, 1: new range, 2: z-score
INSERT INTO "#PARAMS" VALUES ('CONVERGENCE_CRITERION', null, 1.0e-6, null);
INSERT INTO "#PARAMS" VALUES ('MAX_ITERATION', 1000, null, null);
INSERT INTO "#PARAMS" VALUES ('BATCH_SOM', 0, null, null); -- 0: classical, 1: batch
INSERT INTO "#PARAMS" VALUES ('LEARNING_RATE', 1, null, null); -- 1: exponential, 2: linear

TRUNCATE TABLE "MAP";
TRUNCATE TABLE "RESULTS";

CALL "P_SOM" ("V_DATA", "#PARAMS", "MAP", "RESULTS") WITH OVERVIEW;

SELECT * FROM "MAP";
SELECT * FROM "RESULTS";
SELECT * FROM "V_RESULTS";
