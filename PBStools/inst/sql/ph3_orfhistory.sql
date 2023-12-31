/* Sales slip catch summary from PacHarv3 (HARVEST_V2_0) */
SET NOCOUNT ON /* prevents timeout errors */

SELECT
  CS.STP_SPER_YR AS 'year',
  CS.SP_SPECIES_CDE AS 'spp',
  (CASE
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (12,13,14,15,16,17,18,19,20,28,29,9200,9791,9792,9793,9794) THEN 1
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (9508) THEN 2
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (21,22,23,24,121,123,124,9210,9230,9240) THEN 3
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (25,26,27,125,126,127,9250,9260,9270) THEN 4
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (10,11,111,9100,9110) THEN 5
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (7,8,9,107,108,109,110,130,30,9070,9080,9090) THEN 6
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (6,102,106,8021,9021,9060) THEN 7
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (1,3,4,5,101,103,104,105,9010,9031,9032,9033,9040,9050) THEN 8
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (2,142,8022,9022) THEN 9
    ELSE 0 END) AS 'major',
  (CASE
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (142) AND CS.SFA_SMALL_FA_CDE IN (1) THEN 34 /* for POP in Anthony Island (606 records) */
    ELSE 0 END) AS 'minor',
  (CASE
    WHEN CS.SFA_MSFA_MIDSIZE_FA_CDE IN (142) AND CS.SFA_SMALL_FA_CDE IN (1) THEN 1 /* for POP in Anthony Island (606 records) */
    ELSE 0 END) AS 'locality',
  (CONVERT(VARCHAR(10),CS.SFA_MSFA_MIDSIZE_FA_CDE) + '-') + CONVERT(VARCHAR(10),CS.SFA_SMALL_FA_CDE) AS 'region', 
  'CA' AS 'nation',
  CS.CATSUM_ROUND_LBS_WT AS 'catch',
  'lbs' AS 'units',
  CS.GR_GEAR_CDE AS 'gear_code',
  (CASE 
    WHEN CS.GR_GEAR_CDE IN (44,45,46,50,57,99) THEN 'trawl'
    WHEN CS.GR_GEAR_CDE IN (65,68,86,90,91,92,93,94,95,97,98) THEN 'trap'
    WHEN CS.GR_GEAR_CDE IN (40,30,31,32,33,43,7,36,41,42) THEN 'h&l'
    ELSE 'unk' END) AS 'gear'
  FROM
    PH3_CATCH_SUMMARY CS
  WHERE
    CS.SP_SPECIES_CDE IN ('388') AND
    (CS.STP_SPER_YR >=1982 AND CS.STP_SPER_YR <=1995)
  ORDER BY
    CS.STP_SPER_YR


-- qu("ph3_orfhistory.sql",dbName="GFFOS",strSpp="396")

