-- cleanup
DROP TYPE "T_DATA";
DROP TYPE "T_PARAMS";
DROP TYPE "T_STATS";
DROP TYPE "T_ANOVA";
DROP TYPE "T_MULTICOMPARISON";
DROP TABLE "SIGNATURE";
CALL "SYS"."AFLLANG_WRAPPER_PROCEDURE_DROP"('DEVUSER', 'P_ANOVA');
DROP VIEW "V_DATA";
DROP TABLE "STATS";
DROP TABLE "ANOVA";
DROP TABLE "MULTICOMPARISON";

-- procedure setup
CREATE TYPE "T_DATA" AS TABLE ("CLASS" VARCHAR(50), "ATTR1" DOUBLE);
CREATE TYPE "T_PARAMS" AS TABLE ("NAME" VARCHAR(60), "INTARGS" INTEGER, "DOUBLEARGS" DOUBLE, "STRINGARGS" VARCHAR(100));
CREATE TYPE "T_STATS" AS TABLE ("GROUP" VARCHAR(60), "SAMPLES" INTEGER, "MEAN" DOUBLE, "STDDEV" DOUBLE);
CREATE TYPE "T_ANOVA" AS TABLE ("SOURCE" VARCHAR(60), "SUMSQUARES" DOUBLE, "DEGREESFREEDOM" DOUBLE, "MEANSQUARES" DOUBLE, "FRATIO" DOUBLE, "PVALUE" DOUBLE);
CREATE TYPE "T_MULTICOMPARISON" AS TABLE ("FIRST_GROUP" VARCHAR(60), "SECOND_GROUP" VARCHAR(60), "MEANDIFF" DOUBLE, "STDERR" DOUBLE, "PVALUE" DOUBLE, "CL_LOWER" DOUBLE, "CL_UPPER" DOUBLE);

CREATE COLUMN TABLE "SIGNATURE" ("POSITION" INTEGER, "SCHEMA_NAME" NVARCHAR(256), "TYPE_NAME" NVARCHAR(256), "PARAMETER_TYPE" VARCHAR(7));
INSERT INTO "SIGNATURE" VALUES (1, 'DEVUSER', 'T_DATA', 'IN');
INSERT INTO "SIGNATURE" VALUES (2, 'DEVUSER', 'T_PARAMS', 'IN');
INSERT INTO "SIGNATURE" VALUES (3, 'DEVUSER', 'T_STATS', 'OUT');
INSERT INTO "SIGNATURE" VALUES (4, 'DEVUSER', 'T_ANOVA', 'OUT');
INSERT INTO "SIGNATURE" VALUES (5, 'DEVUSER', 'T_MULTICOMPARISON', 'OUT');

CALL "SYS"."AFLLANG_WRAPPER_PROCEDURE_CREATE"('AFLPAL', 'ANOVAONEWAY', 'DEVUSER', 'P_ANOVA', "SIGNATURE");

-- data & view setup
CREATE VIEW "V_DATA" AS 
	SELECT "CLASS", "ATTR1"
		FROM "PAL"."CLASSIFICATION"
	;
CREATE TABLE "STATS" LIKE "T_STATS";
CREATE TABLE "ANOVA" LIKE "T_ANOVA";
CREATE TABLE "MULTICOMPARISON" LIKE "T_MULTICOMPARISON";

-- runtime
DROP TABLE "#PARAMS";
CREATE LOCAL TEMPORARY COLUMN TABLE "#PARAMS" LIKE "T_PARAMS";
INSERT INTO "#PARAMS" VALUES ('MULTCOMP_METHOD', 0, null, null); -- 0: Tukey-Kramer, 1: Bonferroni, 2: Dunn-Sidak, 3: Scheffe, 4: Fisher’s LSD (default:0)
INSERT INTO "#PARAMS" VALUES ('SIGNIFICANCE_LEVEL', null, 0.05, null); -- default 0.05 (0 < 1)

TRUNCATE TABLE "RESULTS";

CALL "P_ANOVA" ("V_DATA", "#PARAMS", "STATS", "ANOVA", "MULTICOMPARISON") WITH OVERVIEW;

SELECT * FROM "STATS";
SELECT * FROM "ANOVA";
SELECT * FROM "MULTICOMPARISON";
